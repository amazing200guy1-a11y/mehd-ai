"""
Mehd AI — Audit Trail (Firebase Firestore)
============================================
Every decision this system makes is logged permanently.
This is not optional. In a financial system, you MUST be able
to answer: "What happened, when, and why?" at any point.

Why Firebase Firestore?
1. Real-time sync — traders can watch decisions stream in live
2. Auto-scaling — no database administration needed
3. Offline support — if the connection drops, Firestore SDKs
   queue writes and sync when back online
4. Document-based — perfect for storing varied event shapes

Why the fallback log?
If Firestore goes down (network issue, quota exceeded, etc.),
we CANNOT stop trading because of a logging failure. So we write
to a local JSON file and retry Firestore on the next event.
In finance, "logging failed so the system crashed" is unacceptable.
"""

from __future__ import annotations

import json
import logging
import os
import uuid
from datetime import datetime, timezone, timedelta
from pathlib import Path
from typing import Any, Optional

from dotenv import load_dotenv

from models import AccountHealth, ConsensusResult, RiskDecision, TradeOrder
from consensus_engine import DEN_IDENTITY

logger = logging.getLogger("mehd.audit_trail")

# Load environment variables
load_dotenv()

# ──────────────────────────────────────────────
#  Firebase initialisation
# ──────────────────────────────────────────────

_firestore_client = None
_firebase_initialised = False

FALLBACK_LOG_PATH = Path(__file__).parent / "fallback_log.json"


def _init_firebase() -> bool:
    """
    Initialise Firebase Admin SDK from the service account key
    file specified in the FIREBASE_CREDENTIALS_PATH env var.

    Returns True if successful, False if not.
    This function is idempotent — calling it multiple times is safe.
    """
    global _firestore_client, _firebase_initialised

    if _firebase_initialised:
        return _firestore_client is not None

    credentials_path = os.getenv("FIREBASE_CREDENTIALS_PATH")
    project_id = os.getenv("FIREBASE_PROJECT_ID")

    if not credentials_path:
        logger.warning(
            "FIREBASE_CREDENTIALS_PATH not set — audit trail will use fallback log only"
        )
        _firebase_initialised = True
        return False

    try:
        import firebase_admin
        from firebase_admin import credentials, firestore

        # Check if already initialised (e.g., in tests or hot-reload)
        if not firebase_admin._apps:
            cred = credentials.Certificate(credentials_path)
            firebase_admin.initialize_app(cred, {
                "projectId": project_id,
            })

        _firestore_client = firestore.client()
        _firebase_initialised = True
        logger.info("Firebase Firestore connected — project: %s", project_id)
        return True

    except Exception as e:
        logger.error("Firebase initialisation failed: %s", e)
        _firebase_initialised = True
        return False


# ──────────────────────────────────────────────
#  AuditLogger class
# ──────────────────────────────────────────────

class AuditLogger:
    """
    Three logging methods, three Firestore collections,
    one fallback file, zero data loss.

    Every document includes:
    - timestamp (UTC)
    - session_id (unique per app session)
    - model_versions (which AI models were used)
    - the full data object
    """

    def __init__(self) -> None:
        self.session_id: str = str(uuid.uuid4())
        self._firestore_available: bool = _init_firebase()
        self._pending_fallback_entries: list[dict] = []

        # Try to flush any previously failed entries
        self._retry_fallback_entries()

        logger.info(
            "AuditLogger initialised — session: %s | Firestore: %s",
            self.session_id,
            "connected" if self._firestore_available else "fallback mode",
        )

    # ──────────────────────────────────────────
    #  Public logging methods
    # ──────────────────────────────────────────

    def log_consensus(self, symbol: str, result: ConsensusResult) -> None:
        """
        Log a consensus decision to the 'consensus_logs' collection.
        Captures every model's vote, the final direction, and whether
        the system allowed the trade to proceed.
        """
        model_versions = [vote.model_name for vote in result.votes]

        now = datetime.now(timezone.utc)
        document = {
            "timestamp": now.isoformat(),
            "expires_at": (now + timedelta(hours=24)).isoformat(),
            "session_id": self.session_id,
            "model_versions": model_versions,
            "symbol": symbol,
            "final_direction": result.final_direction.value,
            "consensus_percentage": result.consensus_percentage,
            "proceed": result.proceed,
            "rejection_reason": result.rejection_reason,
            "votes": [
                {
                    "display_name": DEN_IDENTITY.get(vote.model_name, {}).get("display_name", vote.model_name.upper()),
                    "real_model": vote.model_name,
                    "layer": DEN_IDENTITY.get(vote.model_name, {}).get("layer", "UNKNOWN"),
                    "direction": vote.direction.value,
                    "confidence": vote.confidence,
                    "reasoning": vote.reasoning,
                }
                for vote in result.votes
            ],
        }

        self._write_to_firestore("consensus_logs", document)
        logger.info(
            "Consensus logged: %s → %s (%.1f%%) proceed=%s",
            symbol,
            result.final_direction.value,
            result.consensus_percentage,
            result.proceed,
        )

    def log_trade(self, order: TradeOrder, decision: RiskDecision) -> None:
        """
        Log a trade execution attempt to the 'trade_logs' collection.
        Records both what the trader requested AND what the risk
        engine decided — so we can always reconstruct the full picture.
        """
        document = {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "session_id": self.session_id,
            "model_versions": [],  # Trade execution doesn't involve AI models directly
            "decision_id": str(decision.id),
            "order": {
                "symbol": order.symbol,
                "direction": order.direction.value,
                "lot_size": order.lot_size,
                "stop_loss": order.stop_loss,
                "take_profit": order.take_profit,
                "risk_percentage": order.risk_percentage,
            },
            "risk_decision": {
                "approved": decision.approved,
                "calculated_lot_size": decision.calculated_lot_size,
                "stop_loss": decision.stop_loss,
                "take_profit": decision.take_profit,
                "rejection_reason": decision.rejection_reason,
            },
        }

        self._write_to_firestore("trade_logs", document)
        logger.info(
            "Trade logged: %s %s — approved=%s",
            order.direction.value,
            order.symbol,
            decision.approved,
        )

    def log_account_event(
        self,
        event_type: str,
        account: AccountHealth,
    ) -> None:
        """
        Log an account-level event to the 'account_events' collection.
        Examples: account locked, drawdown updated, balance changed.
        """
        document = {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "session_id": self.session_id,
            "model_versions": [],
            "event_type": event_type,
            "account": {
                "balance": account.balance,
                "equity": account.equity,
                "daily_drawdown_pct": account.daily_drawdown_pct,
                "is_locked": account.is_locked,
                "lock_reason": account.lock_reason,
                "lock_expiry": (
                    account.lock_expiry.isoformat()
                    if account.lock_expiry
                    else None
                ),
            },
        }

        self._write_to_firestore("account_events", document)
        logger.info("Account event logged: %s", event_type)

    # ──────────────────────────────────────────
    #  Private: Firestore write with fallback
    # ──────────────────────────────────────────

    def _write_to_firestore(
        self,
        collection: str,
        document: dict[str, Any],
    ) -> None:
        """
        Try to write to Firestore. If it fails for ANY reason,
        write to the local fallback log file instead.
        NEVER crash the main application because of a logging failure.
        """
        # First, try to flush any pending fallback entries
        if self._pending_fallback_entries:
            self._retry_fallback_entries()

        if self._firestore_available and _firestore_client is not None:
            try:
                doc_id = f"{self.session_id}_{datetime.now(timezone.utc).strftime('%Y%m%d_%H%M%S_%f')}"
                _firestore_client.collection(collection).document(doc_id).set(document)
                return
            except Exception as e:
                logger.error(
                    "Firestore write failed for '%s': %s — falling back to local file",
                    collection,
                    e,
                )

        # Fallback: write to local JSON file
        self._write_to_fallback(collection, document)

    def _write_to_fallback(
        self,
        collection: str,
        document: dict[str, Any],
    ) -> None:
        """
        Append to fallback_log.json. This file is a JSON array
        of objects, each tagged with which Firestore collection
        it was meant for, so we can retry later.
        """
        entry = {
            "target_collection": collection,
            "document": document,
            "failed_at": datetime.now(timezone.utc).isoformat(),
        }

        try:
            # Read existing entries
            existing: list[dict] = []
            if FALLBACK_LOG_PATH.exists():
                try:
                    existing = json.loads(FALLBACK_LOG_PATH.read_text(encoding="utf-8"))
                except (json.JSONDecodeError, ValueError):
                    existing = []

            existing.append(entry)

            FALLBACK_LOG_PATH.write_text(
                json.dumps(existing, indent=2, default=str),
                encoding="utf-8",
            )

            self._pending_fallback_entries.append(entry)
            logger.info(
                "Fallback log written: %s → %s (%d pending entries)",
                collection,
                FALLBACK_LOG_PATH,
                len(self._pending_fallback_entries),
            )

        except Exception as e:
            # Even the fallback failed — log to stdout as absolute last resort
            logger.critical(
                "CRITICAL: Both Firestore AND fallback file failed: %s | Data: %s",
                e,
                json.dumps(entry, default=str),
            )

    def _retry_fallback_entries(self) -> None:
        """
        Attempt to re-send any entries that were written to the
        fallback log file. If Firestore is back, flush them all.
        """
        if not self._firestore_available or _firestore_client is None:
            return

        if not FALLBACK_LOG_PATH.exists():
            self._pending_fallback_entries = []
            return

        try:
            entries: list[dict] = json.loads(
                FALLBACK_LOG_PATH.read_text(encoding="utf-8")
            )
        except (json.JSONDecodeError, ValueError):
            return

        remaining: list[dict] = []

        for entry in entries:
            try:
                collection = entry["target_collection"]
                document = entry["document"]
                doc_id = f"retry_{datetime.now(timezone.utc).strftime('%Y%m%d_%H%M%S_%f')}"
                _firestore_client.collection(collection).document(doc_id).set(document)
                logger.info("Retried fallback entry → %s: success", collection)
            except Exception as e:
                logger.warning("Retry failed for fallback entry: %s", e)
                remaining.append(entry)

        if remaining:
            FALLBACK_LOG_PATH.write_text(
                json.dumps(remaining, indent=2, default=str),
                encoding="utf-8",
            )
        else:
            # All entries flushed — delete the fallback file
            FALLBACK_LOG_PATH.unlink(missing_ok=True)
            logger.info("All fallback entries flushed — fallback file removed")

        self._pending_fallback_entries = remaining

    def get_recent_logs(self, limit: int = 50) -> list[dict]:
        """
        Returns the most recent audit log entries.
        Reads from Firestore if available, otherwise from the fallback file.
        """
        # Try Firestore first
        if self._firestore_available and _firestore_client is not None:
            try:
                docs = (
                    _firestore_client.collection("trade_logs")
                    .order_by("timestamp", direction="DESCENDING")
                    .limit(limit)
                    .stream()
                )
                return [doc.to_dict() for doc in docs]
            except Exception as e:
                logger.warning("Firestore read failed: %s — using fallback", e)

        # Fallback: read from local file
        if FALLBACK_LOG_PATH.exists():
            try:
                entries = json.loads(FALLBACK_LOG_PATH.read_text(encoding="utf-8"))
                trade_entries = [
                    e["document"]
                    for e in entries
                    if e.get("target_collection") == "trade_logs"
                ]
                return trade_entries[-limit:]
            except Exception as e:
                logger.error("Failed to read fallback log: %s", e)

        return []
