import os
import json
import logging
from datetime import datetime, timezone
from typing import Optional
from models import AccountHealth

logger = logging.getLogger("mehd.risk_engine")

class RiskStateStore:
    _STATE_FILE = os.path.join(os.path.dirname(__file__), ".risk_kernel_state.json")

    @classmethod
    def _build_state_dict(cls, account: AccountHealth) -> dict:
        """Build the state dictionary for persistence."""
        return {
            "daily_drawdown_pct": account.daily_drawdown_pct,
            "is_locked": account.is_locked,
            "lock_reason": account.lock_reason,
            "lock_expiry": account.lock_expiry.isoformat() if account.lock_expiry else None,
            "saved_at": datetime.now(timezone.utc).isoformat(),
        }

    @classmethod
    def persist_state(cls, account: AccountHealth) -> None:
        """Save safety-critical state to file (sync) and storage backend (async)."""
        state = cls._build_state_dict(account)
        
        # Immediate sync write (local file)
        try:
            with open(cls._STATE_FILE, "w") as f:
                json.dump(state, f)
        except Exception as e:
            logger.warning("Could not persist risk state to file: %s", e)
        
        # Async write to storage backend (multi-replica consistency)
        try:
            import asyncio
            loop = asyncio.get_running_loop()
            loop.create_task(cls._persist_state_to_storage(state))
        except RuntimeError:
            pass  # No event loop running (e.g. during __init__)

    @classmethod
    async def _persist_state_to_storage(cls, state: dict) -> None:
        """Async write to the storage backend."""
        try:
            from storage import storage
            await storage.set("risk_kernel_state", "global", state)
        except Exception as e:
            logger.warning("Could not persist risk state to storage backend: %s", e)

    @classmethod
    async def restore_from_storage(cls, account: AccountHealth) -> Optional[AccountHealth]:
        """Async restore from storage backend."""
        try:
            from storage import storage
            state = await storage.get("risk_kernel_state", "global")
            if state:
                updated_account = cls.apply_restored_state(state, account)
                if updated_account:
                    logger.info("Risk state restored from storage backend (multi-replica aware)")
                    return updated_account
        except Exception as e:
            logger.debug("Storage backend restore failed: %s", e)
        return None

    @classmethod
    def apply_restored_state(cls, state: dict, account: AccountHealth) -> Optional[AccountHealth]:
        """Apply restored state dict to account health. Returns new AccountHealth or None."""
        saved_at = state.get("saved_at", "")
        if saved_at:
            try:
                saved_date = datetime.fromisoformat(saved_at).date()
                today = datetime.now(timezone.utc).date()
                if saved_date != today:
                    logger.info("Risk state from yesterday — daily drawdown reset to 0%")
                    return None
            except ValueError:
                return None
        
        updates = {"daily_drawdown_pct": state.get("daily_drawdown_pct", 0.0)}
        if state.get("is_locked"):
            updates["is_locked"] = True
            updates["lock_reason"] = state.get("lock_reason")
            if state.get("lock_expiry"):
                try:
                    updates["lock_expiry"] = datetime.fromisoformat(state["lock_expiry"])
                except ValueError as e:
                    logger.warning("Failed to parse lock expiry: %s", e)
        
        updated_account = account.model_copy(update=updates)
        logger.info("Restored risk state: drawdown=%.2f%%, locked=%s", 
                    updated_account.daily_drawdown_pct, updated_account.is_locked)
        return updated_account

    @classmethod
    def restore_state(cls, account: AccountHealth) -> AccountHealth:
        """Restore drawdown/lock state from local file fallback."""
        try:
            if not os.path.exists(cls._STATE_FILE):
                return account
            with open(cls._STATE_FILE, "r") as f:
                state = json.load(f)
            updated = cls.apply_restored_state(state, account)
            if updated:
                return updated
        except Exception as e:
            logger.critical("Could not restore risk state from file (FAIL CLOSED): %s", e)
            return account.model_copy(update={
                "is_locked": True,
                "lock_reason": "Safety Kernel State Corrupted. Manual intervention required."
            })
        return account
