"""
Mehd AI — The Sniper Engine (Virtual Stop Loss Worker)
======================================================
This background worker constantly monitors the live market feed and compares it
against our "secret vault" of Stop Losses and Take Profits. 

Because we do not send the SL/TP to the broker, the broker cannot hunt them.
This script acts as the trigger finger, instantly closing trades if the price hits our secret bounds.
"""

import asyncio
import logging
from storage import storage
from state import streamer
from broker_gateway import broker_gateway

logger = logging.getLogger("mehd.virtual_stop_worker")

class VirtualStopWorker:
    def __init__(self):
        self._running = False
        self._task = None
        # In-memory guard: prevents double-close during Firestore delete propagation window
        self._closing_trades: set = set()

    def start(self):
        if not self._running:
            self._running = True
            self._task = asyncio.create_task(self._loop())
            logger.info("🎯 Sniper Engine (Virtual Stops) started.")

    def stop(self):
        self._running = False
        if self._task:
            self._task.cancel()
        logger.info("🎯 Sniper Engine (Virtual Stops) stopped.")

    async def _loop(self):
        await asyncio.sleep(5)  # Boot delay
        while self._running:
            try:
                # We check 5 times a second (200ms latency)
                await self._check_stops()
                await asyncio.sleep(0.2) 
            except Exception as e:
                logger.error(f"Sniper Engine error: {e}")
                await asyncio.sleep(1)

    async def _check_stops(self):
        stops = await storage.get_all("virtual_stops")
        if not stops:
            return

        for trade_id, data in stops.items():
            symbol = data.get("symbol")
            direction = data.get("direction")
            stop_loss = data.get("stop_loss")
            take_profit = data.get("take_profit")
            account_id = data.get("account_id")

            if not all([symbol, direction, account_id]):
                continue

            snap = streamer.get_latest_snapshot(symbol)
            if snap is None or snap.bid == 0.0:
                continue

            # Check logic based on direction
            close_reason = None
            if direction.upper() == "BUY":
                # For a BUY, we close if the BID price drops below SL or jumps above TP
                if stop_loss and snap.bid <= stop_loss:
                    close_reason = f"Hit Virtual Stop Loss @ {snap.bid}"
                elif take_profit and snap.bid >= take_profit:
                    close_reason = f"Hit Virtual Take Profit @ {snap.bid}"
            elif direction.upper() == "SELL":
                # For a SELL, we close if the ASK price jumps above SL or drops below TP
                if stop_loss and snap.ask >= stop_loss:
                    close_reason = f"Hit Virtual Stop Loss @ {snap.ask}"
                elif take_profit and snap.ask <= take_profit:
                    close_reason = f"Hit Virtual Take Profit @ {snap.ask}"

            # If a bound is hit, fire the close trade command!
            if close_reason:
                # Guard: skip if already being closed (prevents double-call in 200ms propagation window)
                if trade_id in self._closing_trades:
                    continue
                self._closing_trades.add(trade_id)
                logger.critical(f"🎯 SNIPER TRIGGER: {close_reason} | Trade ID: {trade_id}")
                success = await broker_gateway.close_trade(trade_id, account_id)
                if success:
                    # Remove from active monitoring vault
                    await storage.delete("virtual_stops", trade_id)
                    self._closing_trades.discard(trade_id)
                else:
                    # Release lock on failure so it retries next cycle
                    self._closing_trades.discard(trade_id)
                    logger.error(f"Failed to close trade {trade_id} via Sniper Engine!")

# Singleton
virtual_stop_worker = VirtualStopWorker()
