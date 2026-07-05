import asyncio
import logging
from datetime import datetime, timezone, timedelta

from storage import storage
from state import streamer  # FIX #1: was wrongly importing from data_streamer

logger = logging.getLogger("mehd.weekly_scan")

# The 3 pairs the weekly scan covers for Free Tier users.
SCAN_PAIRS = ["EUR/USD", "XAU/USD", "BTC/USD"]

# Only process observer (free) users — paid users get real-time data.
FREE_TIER = "observer"


class WeeklyScanWorker:
    """
    Background daemon that generates weekly AI scans for Free Tier (Observer) users.

    ARCHITECTURE (v2 — Cost-Safe):
    ─────────────────────────────
    The old version called den_engine.analyze() per user × 3 pairs, which
    would cost ~$1,500 per batch on 10k users. This version instead:

      1. Snapshots the Broadcaster's current cached results for the 3 scan pairs.
      2. Assigns those shared results to every eligible Observer user.

    This reduces cost to near-zero (Firestore reads only), because the
    Broadcaster has already run and cached the consensus analysis.

    ELIGIBILITY:
    ─────────────────────────────
    A user is eligible if:
      - They are on the Observer (free) tier.
      - They have never received a weekly scan, OR their last scan is > 7 days old.

    SAFETY:
    ─────────────────────────────
    - A distributed lock prevents concurrent execution across replicas.
    - The worker runs every 6 hours. If no broadcaster data is ready yet,
      the batch is skipped gracefully with a warning.
    """

    def __init__(self):
        self._running = False
        self._task = None

    def start(self):
        if not self._running:
            self._running = True
            self._task = asyncio.create_task(self._loop())
            logger.info("📅 Weekly Scan Worker started.")

    def stop(self):
        self._running = False
        if self._task:
            self._task.cancel()
            logger.info("📅 Weekly Scan Worker stopped.")

    async def _loop(self):
        # Allow server to fully initialize before first run.
        await asyncio.sleep(180)

        while self._running:
            try:
                await self._process_weekly_scans()
            except asyncio.CancelledError:
                break
            except Exception as e:
                logger.error(f"WeeklyScanWorker error: {e}", exc_info=True)

            try:
                await asyncio.sleep(21600)  # Run every 6 hours
            except asyncio.CancelledError:
                break

    async def _process_weekly_scans(self):
        """
        Finds eligible Observer users and stamps their weekly scan record
        with the broadcaster's current cached consensus data.
        """
        # SAFETY: Acquire a distributed lock so only one replica runs at a time.
        lock_key = "weekly_scan_worker_lock"
        acquired = await storage.acquire_lock(lock_key, ttl_seconds=3600)
        if not acquired:
            logger.warning("📅 Weekly Scan Worker: another replica is running. Skipping batch.")
            return

        try:
            logger.info("📅 Starting weekly scan batch...")
            now = datetime.now(timezone.utc)
            seven_days_ago = now - timedelta(days=7)

            # STEP 1: Build shared scan payload from Broadcaster cache.
            # This is the key cost-optimization: one analysis serves all users.
            global_scan = await self._build_global_scan_payload(now)
            if not global_scan:
                logger.warning(
                    "📅 Weekly scan skipped — Broadcaster has no cached data yet for scan pairs. "
                    "Will retry next cycle."
                )
                return

            # STEP 2: Iterate over users.
            # FIX #2: was iterating 'user_tiers' which only contains users who *changed* tier
            # (i.e., mostly paid users). The correct source is the 'users' collection.
            processed_count = 0
            skipped_count = 0

            async for chunk in storage.stream_collection("users", chunk_size=500):
                for user_id, user_data in chunk.items():
                    if not self._running:
                        return

                    # Only generate scans for free-tier users.
                    tier = user_data.get("tier", FREE_TIER)
                    if tier != FREE_TIER:
                        skipped_count += 1
                        continue

                    # Check eligibility: no scan ever, or last scan > 7 days ago.
                    last_scan_record = await storage.get("weekly_scans", user_id)
                    eligible = self._is_eligible(last_scan_record, seven_days_ago)

                    if eligible:
                        scan_record = {
                            "user_id": user_id,
                            "timestamp": now.isoformat(),
                            "results": global_scan,
                            "tier": tier,
                        }
                        await storage.set("weekly_scans", user_id, scan_record)
                        processed_count += 1

                        # Micro-yield to keep the event loop responsive.
                        # No large sleep needed — we're just writing to Firestore.
                        if processed_count % 100 == 0:
                            await asyncio.sleep(0)

            logger.info(
                f"📅 Weekly scan batch complete. "
                f"Generated: {processed_count} | Skipped (paid): {skipped_count}"
            )
        finally:
            await storage.release_lock(lock_key)

    def _is_eligible(self, last_scan_record: dict | None, cutoff: datetime) -> bool:
        """Returns True if the user should receive a new weekly scan."""
        if not last_scan_record:
            return True
        last_scan_time_str = last_scan_record.get("timestamp")
        if not last_scan_time_str:
            return True
        try:
            last_scan_time = datetime.fromisoformat(last_scan_time_str)
            # Ensure timezone-aware comparison
            if last_scan_time.tzinfo is None:
                last_scan_time = last_scan_time.replace(tzinfo=timezone.utc)
            return last_scan_time < cutoff
        except (ValueError, TypeError):
            return True

    async def _build_global_scan_payload(self, now: datetime) -> list[dict] | None:
        """
        Reads the Broadcaster's in-memory cache for the 3 scan pairs.
        Returns a list of result dicts, or None if no data is available.

        This costs zero API calls — the Broadcaster already did the heavy lifting.
        """
        from broadcaster import broadcaster

        results = []
        for symbol in SCAN_PAIRS:
            signal = broadcaster.get_latest(symbol)
            if signal is None:
                logger.warning(f"📅 No broadcaster signal cached for {symbol}. Skipping pair.")
                continue

            # Only surface actionable signals.
            if signal.consensus.consensus_percentage > 0:
                results.append({
                    "symbol": symbol,
                    "direction": signal.consensus.final_direction.value,
                    "confidence": signal.consensus.consensus_percentage,
                    "price": signal.snapshot.bid,
                    "broadcast_time": signal.broadcast_time.isoformat(),
                    "generated_at": now.isoformat(),
                })

        return results if results else None


weekly_scan_worker = WeeklyScanWorker()
