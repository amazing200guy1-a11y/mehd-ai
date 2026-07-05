"""
Mehd AI — Per-User Risk State Store
=====================================
WHY THIS EXISTS:
The HardRiskKernel originally tracked ONE global account state.
That works for a single user, but when millions of traders are
on the platform, each user needs their own:
  - Balance tracking
  - Daily drawdown counter
  - Account lock state
  - Trade count

This module provides per-user isolation using the existing
storage abstraction (memory in dev, Firestore in production).

USAGE:
    from user_risk_store import user_risk_store
    
    # Get a user's risk state
    state = await user_risk_store.get_state("user_123")
    
    # Update drawdown after a loss
    await user_risk_store.update_drawdown("user_123", loss_pct=0.5)
    
    # Lock a user's account
    await user_risk_store.lock_account("user_123", "Daily drawdown exceeded 3%")
"""

from __future__ import annotations

import logging
from datetime import datetime, timedelta, timezone
from typing import Optional

from pydantic import BaseModel, Field

logger = logging.getLogger("mehd.user_risk_store")


class UserRiskState(BaseModel):
    """Per-user risk tracking state."""
    uid: str
    balance: float = Field(default=10_000.0, ge=0)
    equity: float = Field(default=10_000.0, ge=0)
    daily_drawdown_pct: float = Field(default=0.0, ge=0, le=100)
    daily_trades_count: int = Field(default=0, ge=0)
    is_locked: bool = Field(default=False)
    lock_reason: Optional[str] = None
    lock_expiry: Optional[str] = None  # ISO format string for serialization
    last_reset_date: str = Field(default="")  # YYYY-MM-DD
    tier: str = Field(default="observer")
    updated_at: str = Field(default="")
    encrypted_broker_key: Optional[str] = Field(default=None, description="AES encrypted broker key for this user")


class UserRiskStore:
    """
    Per-user risk state management.
    
    Uses the storage abstraction layer so it works with both
    MemoryStorage (dev) and FirestoreStorage (production).
    """

    COLLECTION = "user_risk_states"
    MAX_DAILY_DRAWDOWN_PCT = 3.0
    LOCKOUT_HOURS = 24

    async def get_state(self, uid: str) -> UserRiskState:
        """Get a user's risk state. Creates default if not found."""
        from storage import storage
        
        data = await storage.get(self.COLLECTION, uid)
        if data:
            # Check if we need to reset daily counters
            state = UserRiskState(**data)
            today = datetime.now(timezone.utc).strftime("%Y-%m-%d")
            if state.last_reset_date != today:
                state.daily_drawdown_pct = 0.0
                state.daily_trades_count = 0
                state.last_reset_date = today
                # Auto-unlock if lock expired
                if state.is_locked and state.lock_expiry:
                    try:
                        expiry = datetime.fromisoformat(state.lock_expiry)
                        if datetime.now(timezone.utc) >= expiry:
                            state.is_locked = False
                            state.lock_reason = None
                            state.lock_expiry = None
                    except (ValueError, TypeError) as e:
                        logger.warning("Failed to parse lock_expiry for %s: %s", uid, e)
                await self._save_state(uid, state)
            return state
        
        # Create default state for new user
        default = UserRiskState(
            uid=uid,
            last_reset_date=datetime.now(timezone.utc).strftime("%Y-%m-%d"),
        )
        await self._save_state(uid, default)
        return default

    async def update_drawdown(self, uid: str, loss_pct: float) -> UserRiskState:
        """
        Update a user's daily drawdown after a losing trade.
        If drawdown exceeds 3%, auto-lock the account.
        """
        state = await self.get_state(uid)
        state.daily_drawdown_pct += loss_pct
        state.updated_at = datetime.now(timezone.utc).isoformat()

        if state.daily_drawdown_pct >= self.MAX_DAILY_DRAWDOWN_PCT:
            expiry = datetime.now(timezone.utc) + timedelta(hours=self.LOCKOUT_HOURS)
            state.is_locked = True
            state.lock_reason = (
                f"Daily drawdown hit {state.daily_drawdown_pct:.2f}% "
                f"(limit: {self.MAX_DAILY_DRAWDOWN_PCT}%)"
            )
            state.lock_expiry = expiry.isoformat()
            logger.critical(
                "USER %s ACCOUNT LOCKED: %s — Unlocks at %s",
                uid, state.lock_reason, state.lock_expiry,
            )

        await self._save_state(uid, state)
        return state

    async def increment_trades(self, uid: str) -> int:
        """Increment daily trade count. Returns new count."""
        state = await self.get_state(uid)
        state.daily_trades_count += 1
        state.updated_at = datetime.now(timezone.utc).isoformat()
        await self._save_state(uid, state)
        return state.daily_trades_count

    async def lock_account(self, uid: str, reason: str) -> None:
        """Manually lock a user's account."""
        state = await self.get_state(uid)
        expiry = datetime.now(timezone.utc) + timedelta(hours=self.LOCKOUT_HOURS)
        state.is_locked = True
        state.lock_reason = reason
        state.lock_expiry = expiry.isoformat()
        state.updated_at = datetime.now(timezone.utc).isoformat()
        await self._save_state(uid, state)
        logger.critical("USER %s LOCKED: %s", uid, reason)

    async def unlock_account(self, uid: str) -> None:
        """Unlock a user's account and reset drawdown."""
        state = await self.get_state(uid)
        state.is_locked = False
        state.lock_reason = None
        state.lock_expiry = None
        state.daily_drawdown_pct = 0.0
        state.updated_at = datetime.now(timezone.utc).isoformat()
        await self._save_state(uid, state)
        logger.info("USER %s UNLOCKED", uid)

    async def sync_balance(self, uid: str, balance: float, equity: float) -> None:
        """Sync a user's balance from their broker connection."""
        state = await self.get_state(uid)
        state.balance = balance
        state.equity = equity
        state.updated_at = datetime.now(timezone.utc).isoformat()
        await self._save_state(uid, state)

    async def is_locked(self, uid: str) -> bool:
        """Quick check if a user's account is locked."""
        state = await self.get_state(uid)
        if state.is_locked and state.lock_expiry:
            try:
                expiry = datetime.fromisoformat(state.lock_expiry)
                if datetime.now(timezone.utc) >= expiry:
                    await self.unlock_account(uid)
                    return False
            except (ValueError, TypeError) as e:
                logger.warning("Failed to parse lock_expiry for %s: %s", uid, e)
        return state.is_locked

    async def set_broker_key(self, uid: str, plain_text_key: str) -> None:
        """Encrypts and saves a user's broker key at rest."""
        from secrets_manager import encryption
        state = await self.get_state(uid)
        state.encrypted_broker_key = encryption.encrypt(plain_text_key)
        state.updated_at = datetime.now(timezone.utc).isoformat()
        await self._save_state(uid, state)
        logger.info("USER %s: Broker key encrypted and saved.", uid)

    async def get_broker_key(self, uid: str) -> Optional[str]:
        """Loads and decrypts a user's broker key."""
        from secrets_manager import encryption
        state = await self.get_state(uid)
        if not state.encrypted_broker_key:
            return None
        return encryption.decrypt(state.encrypted_broker_key)

    async def _save_state(self, uid: str, state: UserRiskState) -> None:
        """Persist state to storage."""
        from storage import storage
        await storage.set(self.COLLECTION, uid, state.model_dump())


# Singleton
user_risk_store = UserRiskStore()
