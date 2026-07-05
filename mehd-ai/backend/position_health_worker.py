import asyncio
import logging
from datetime import datetime, timezone, timedelta

from storage import storage
from state import streamer
from models import get_pip_size

logger = logging.getLogger("mehd.position_health")

class PositionHealthWorker:
    """
    Background worker that monitors open user positions and calculates
    real-time "Health Scores" (0-100).
    
    Factors:
    - Drawdown vs estimated SL
    - Latest AI Consensus direction
    - Time-in-trade decay
    """
    
    def __init__(self):
        self._running = False
        self._task = None

    def start(self):
        if not self._running:
            self._running = True
            self._task = asyncio.create_task(self._loop())
            logger.info("🏥 Position Health Worker started.")

    def stop(self):
        self._running = False
        if self._task:
            self._task.cancel()
        logger.info("🏥 Position Health Worker stopped.")

    async def _loop(self):
        await asyncio.sleep(10)  # Boot delay
        while self._running:
            try:
                # Run every 5 minutes
                await self._calculate_all_health()
                await asyncio.sleep(300) 
            except Exception as e:
                logger.error(f"Health loop error: {e}")
                await asyncio.sleep(60)

    async def _calculate_all_health(self):
        """Iterate over all active user positions and update health scores."""
        positions = await storage.get_all("user_positions")
        if not positions:
            return

        logger.info(f"🏥 Calculating health for {len(positions)} positions...")
        
        # Cache market data to avoid duplicate fetches per symbol
        market_cache = {}

        for pos_key, data in positions.items():
            try:
                symbol = data.get("symbol")
                user_id = data.get("user_id", "unknown")
                entry_price = data.get("entry_price")
                direction = data.get("direction")
                raw_timestamp = data.get("timestamp")

                # --- EDGE CASE GUARD: Missing required fields ---
                # NOTE: Use 'is not None' for entry_price because 0.0 is
                # falsy in Python but valid for paper/demo trades.
                if not symbol or entry_price is None or not direction:
                    logger.warning(
                        f"Health skip: missing fields | pos={pos_key} "
                        f"user={user_id} symbol={symbol}"
                    )
                    continue

                # --- EDGE CASE GUARD: Malformed or missing timestamp ---
                if not raw_timestamp:
                    logger.warning(
                        f"Health skip: no timestamp | pos={pos_key} "
                        f"user={user_id} symbol={symbol}"
                    )
                    continue
                try:
                    entry_time = datetime.fromisoformat(raw_timestamp)
                except (ValueError, TypeError):
                    logger.warning(
                        f"Health skip: malformed timestamp '{raw_timestamp}' | "
                        f"pos={pos_key} user={user_id} symbol={symbol}"
                    )
                    continue

                # --- EDGE CASE GUARD: Ensure timezone-aware comparison ---
                # If entry_time is naive, assume UTC
                if entry_time.tzinfo is None:
                    entry_time = entry_time.replace(tzinfo=timezone.utc)
                
                # 1. Get Live Price
                if symbol not in market_cache:
                    market_cache[symbol] = streamer.get_latest_snapshot(symbol)
                
                snapshot = market_cache[symbol]
                if not snapshot:
                    continue
                if snapshot.bid <= 0 or snapshot.ask <= 0:
                    continue  # Market closed or streamer warming up
                
                live_price = snapshot.bid if direction == "BUY" else snapshot.ask
                pip_size = get_pip_size(symbol)

                # --- EDGE CASE GUARD: Zero pip_size prevents ZeroDivisionError ---
                if not pip_size or pip_size <= 0:
                    logger.error(
                        f"Health CRITICAL: pip_size is {pip_size} for {symbol} | "
                        f"pos={pos_key} user={user_id}. Skipping to prevent crash."
                    )
                    continue
                
                # 2. Calculate Pip Diff (Drawdown)
                pip_diff = (live_price - entry_price) / pip_size
                if direction == "SELL":
                    pip_diff = -pip_diff
                
                # 3. Base Health
                health = 100.0
                
                # Penalty for drawdown (30 pips = -45% health)
                if pip_diff < 0:
                    health -= min(60, abs(pip_diff) * 1.5)
                else:
                    # Bonus for profit (capped)
                    health += min(10, pip_diff * 0.5)

                # 4. Time Decay (institutional trades shouldn't sit stale for days)
                hours_in = (datetime.now(timezone.utc) - entry_time).total_seconds() / 3600
                health -= (hours_in * 1.5)  # -1.5% per hour

                # 5. TODO: Incorporate latest AI Consensus (Phase 3)
                # If AI flips direction, health should tank.

                health = max(0, min(100, round(health, 1)))
                
                # Persist health score
                health_data = {
                    "score": health,
                    "last_updated": datetime.now(timezone.utc).isoformat(),
                    "expires_at": (datetime.now(timezone.utc) + timedelta(hours=24)).isoformat(),
                    "pip_pnl": round(pip_diff, 1),
                    "symbol": symbol,
                    "user_id": user_id,  # Required by Firestore security rule
                }
                
                await storage.set("position_health", pos_key, health_data)
                
            except Exception as e:
                logger.warning(
                    f"Health calc failed | pos={pos_key} "
                    f"user={data.get('user_id', '?')} "
                    f"symbol={data.get('symbol', '?')} "
                    f"phase=health_calculation | error={e}",
                    exc_info=True
                )

# Global instance
health_worker = PositionHealthWorker()
