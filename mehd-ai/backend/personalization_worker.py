"""
Mehd AI — Personalization Worker (The Chairman's Voice)
=========================================================
WHAT THIS DOES:
  Sits between the global Broadcaster and each individual user.
  When the 11-agent consensus finds a high-conviction signal, this
  worker writes a personalized brief directly to that user's private
  Firestore ticker feed, and optionally sends a targeted push notification.

SELF-CORRECTION NOTES (v2):
  - BUG FIX: Was using storage.set("user_profiles/{uid}/ticker_feed", ...)
    which is INVALID — the storage abstraction only supports root collections.
    Subcollection writes MUST use Firebase Admin SDK directly.
  - BUG FIX: start() is now called inside the DECOUPLED_WORKER_MODE guard
    in main.py so it doesn't double-start in containerized deployments.
  - BUG FIX: The loop now has crash-recovery backoff. If the broadcaster
    restarts mid-stream, the loop reconnects instead of dying permanently.
"""

import asyncio
import logging
from datetime import datetime, timezone, timedelta
import random

from storage import storage
from notification_service import send_personalized_ticker_alert
from models import AutopilotConfig

logger = logging.getLogger("mehd.personalization")


def _get_firestore_db():
    """Safely retrieve the Firebase Admin Firestore client."""
    try:
        from firebase_admin import firestore
        return firestore.client()
    except Exception:
        return None


class PersonalizationWorker:
    """
    The Personal Intelligence Layer.
    Listens to the global broadcast and translates it into personalized,
    actionable sentences for each user based on their profile and autopilot state.
    """
    def __init__(self):
        self._running = False
        self._task = None

    def start(self):
        if not self._running:
            self._running = True
            self._task = asyncio.create_task(self._loop())
            logger.info("🤖 Personalization Worker started (Chairman's Voice online).")

    def stop(self):
        self._running = False
        if self._task:
            self._task.cancel()
        logger.info("🤖 Personalization Worker stopped.")

    async def _loop(self):
        """
        Main loop. Connects to the broadcaster and processes signals.
        Includes crash-recovery backoff — if the broadcaster stream ends
        unexpectedly (e.g. during a restart), we wait and reconnect.
        """
        # Give the broadcaster time to fully start up
        await asyncio.sleep(15)

        consecutive_crashes = 0
        while self._running:
            try:
                # Import here to avoid circular import at module load time
                from broadcaster import broadcaster

                logger.info("📡 Personalization loop connecting to broadcast stream...")

                async for signal in broadcaster.subscribe():
                    if not self._running:
                        return

                    # HEARTBEAT is a keep-alive string, not a real signal
                    if signal == "HEARTBEAT":
                        continue

                    try:
                        await self._process_signal(signal)
                    except Exception as e:
                        logger.error(f"Personalization processing error for signal: {e}")

                # If we exit the loop cleanly, the broadcaster stopped
                consecutive_crashes = 0

            except asyncio.CancelledError:
                return
            except Exception as e:
                consecutive_crashes += 1
                backoff = min(60.0, 5.0 * consecutive_crashes)
                logger.error(f"Personalization loop crashed (attempt {consecutive_crashes}): {e}. Reconnecting in {backoff}s...")
                await asyncio.sleep(backoff)

    async def _process_signal(self, signal):
        """
        Filter a global broadcast signal and write personalized briefs
        to each relevant user's private Firestore ticker feed.
        """
        symbol = signal.symbol
        consensus_pct = signal.consensus.consensus_percentage

        # Only push high-conviction signals to prevent ticker spam
        if consensus_pct < 75:
            return

        direction = signal.consensus.final_direction.value
        db = _get_firestore_db()

        # Build a stable feed document ID (one per symbol per broadcast)
        feed_id = f"{symbol.replace('/', '_')}_{int(datetime.now(timezone.utc).timestamp())}"

        # Stream all users who have an autopilot config (active traders)
        async for chunk in storage.stream_collection("autopilot_configs", chunk_size=500):
            for uid, raw_cfg in chunk.items():
                try:
                    cfg = AutopilotConfig.model_validate(raw_cfg)

                    # Generate the Chairman's personalized brief
                    message = self._generate_chairman_sentence(uid, symbol, direction, consensus_pct, cfg)

                    ticker_data = {
                        "symbol": symbol,
                        "message": message,
                        "timestamp": datetime.now(timezone.utc).isoformat(),
                        "expires_at": (datetime.now(timezone.utc) + timedelta(hours=24)).isoformat(),
                        "direction": direction,
                        "consensus_pct": round(consensus_pct, 1),
                        "status": "UNREAD",
                    }

                    # ── Write to Firestore subcollection directly ──────────
                    # storage.set() CANNOT write to subcollections — it only
                    # supports root-level collections. We must use Firebase
                    # Admin SDK directly for user_profiles/{uid}/ticker_feed.
                    if db is not None:
                        doc_ref = (
                            db.collection("user_profiles")
                              .document(uid)
                              .collection("ticker_feed")
                              .document(feed_id)
                        )
                        await asyncio.to_thread(doc_ref.set, ticker_data)
                    else:
                        # Firestore unavailable: fall back to root-level flat store
                        await storage.set("personalization_ticker", f"{uid}_{feed_id}", ticker_data)

                    # ── Targeted Push Notification (>85% conviction only) ──
                    # Guard is intentionally tighter than the feed threshold (75%)
                    # to prevent notification fatigue.
                    if consensus_pct >= 85:
                        await send_personalized_ticker_alert(uid, symbol, message)

                except Exception as e:
                    logger.warning(f"Failed to personalize for user {uid}: {e}")

    def _generate_chairman_sentence(
        self, uid: str, symbol: str, direction: str, pct: float, cfg: AutopilotConfig
    ) -> str:
        """
        Generates a 1-sentence personalized brief for the user.
        When real API keys are available, this becomes a lightweight LLM call.
        Until then, it uses a curated template pool that still reads premium.
        """
        pct_str = f"{round(pct, 1)}%"

        if direction == "BUY":
            candidates = [
                f"{symbol} is building serious buy pressure ({pct_str} consensus).",
                f"The Den is signalling a structural breakout on {symbol}.",
                f"Institutional accumulation detected on {symbol} — {pct_str} conviction.",
            ]
        elif direction == "SELL":
            candidates = [
                f"{symbol} structure is breaking down ({pct_str} SELL consensus).",
                f"Smart money appears to be distributing {symbol}.",
                f"The Den flagged a potential reversal on {symbol} at {pct_str}.",
            ]
        else:
            candidates = [
                f"The Den is monitoring {symbol} — no clear directional conviction yet.",
            ]

        base = random.choice(candidates)

        # Add autopilot-aware context suffix
        if cfg.enabled and not cfg.frozen:
            base += " Your autopilot is armed and standing by."
        elif cfg.frozen:
            base += " ⚠ Your autopilot is FROZEN — manual review required."
        else:
            base += " Autopilot is offline — manual review recommended."

        return base


# Singleton instance
personalization_worker = PersonalizationWorker()

