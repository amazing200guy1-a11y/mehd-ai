import re

with open(r"c:\Mehd ai\mehd-ai\backend\auto_execution_worker.py", "r", encoding="utf-8") as f:
    code = f.read()

start_idx = code.find("    async def _process_pending_signals(self):")
end_idx = code.find("    def _calculate_pullback_level")

new_code_block = """    async def _process_pending_signals(self):
        pending = await storage.get_all("pending_auto_executions")
        if not pending:
            return

        system_pause = await storage.get("system_state", "pause_flag")
        if system_pause:
            logger.warning("SYSTEM_PAUSE active. Circuit breaker tripped. Dropping all pending signals.")
            for sig_id in pending.keys():
                await storage.delete("pending_auto_executions", sig_id)
            return

        for sig_id, signal_data in pending.items():
            try:
                self._arm_sniper(sig_id, signal_data)
            finally:
                # Always remove from pending; Sniper takes over
                await storage.delete("pending_auto_executions", sig_id)

    def _arm_sniper(self, sig_id: str, signal_data: dict):
        symbol = signal_data.get("symbol")
        direction_str = signal_data.get("direction")
        
        if not symbol or direction_str not in ["BUY", "SELL"]:
            return
            
        current_price = signal_data.get("current_price", 0.0)
        if current_price <= 0.0:
            return

        # Prevent duplicate entries on same symbol (Execution Lock)
        if symbol in self.pending_sniper_entries:
            return
            
        pip_size = 0.01 if "JPY" in symbol.upper() else (0.1 if "XAU" in symbol.upper() else 0.0001)
        if "XAU" in symbol.upper():
            pip_size = 1.0 # $1 for gold calculations

        # Sniper static parameters
        pullback_pips = 2.0
        runaway_pips = 5.0
        
        pullback_dist = pullback_pips * pip_size
        runaway_dist = runaway_pips * pip_size
        
        if direction_str == "BUY":
            target_price = round(current_price - pullback_dist, 5)
            cancel_price = round(current_price + runaway_dist, 5)
        else:
            target_price = round(current_price + pullback_dist, 5)
            cancel_price = round(current_price - runaway_dist, 5)

        self.pending_sniper_entries[symbol] = {
            "sig_id": sig_id,
            "signal_data": signal_data,
            "analysis_price": current_price,
            "target_price": target_price,
            "cancel_price": cancel_price,
            "timestamp": datetime.now(timezone.utc),
            "direction": direction_str
        }
        logger.info(f"🎯 SNIPER ARMED for {symbol}. Dir: {direction_str}, Analyzed: {current_price}, Pullback Target: {target_price}, Cancel at: {cancel_price}")

    async def _sniper_loop(self):
        import asyncio
        from datetime import datetime, timezone
        from storage import storage
        import logging
        
        await asyncio.sleep(5)
        while self._running:
            try:
                now = datetime.now(timezone.utc)
                symbols_to_remove = []
                
                # Check Circuit Breaker mid-hunt
                system_pause = await storage.get("system_state", "pause_flag")
                if system_pause:
                    self.pending_sniper_entries.clear()
                    await asyncio.sleep(1)
                    continue

                for symbol, data in list(self.pending_sniper_entries.items()):
                    # Timeout check (120s)
                    if (now - data["timestamp"]).total_seconds() > 120:
                        logger.warning(f"Sniper timeout for {symbol}. Cancelled (TIMEOUT_NO_ENTRY).")
                        symbols_to_remove.append(symbol)
                        continue

                    # Get live price (Price Consistency check: Bid vs Ask)
                    try:
                        from data_streamer import streamer
                        snapshot = streamer.get_latest_snapshot(symbol)
                        if not snapshot: continue
                        
                        if data["direction"] == "BUY":
                            live_price = snapshot.ask
                        else:
                            live_price = snapshot.bid
                            
                    except Exception:
                        continue # Streamer unavailable

                    # Runaway cancel check
                    is_runaway = False
                    if data["direction"] == "BUY" and live_price >= data["cancel_price"]: is_runaway = True
                    if data["direction"] == "SELL" and live_price <= data["cancel_price"]: is_runaway = True
                    
                    if is_runaway:
                        logger.warning(f"Sniper runaway for {symbol}. Price moved too far profitably without pullback. Cancelled.")
                        symbols_to_remove.append(symbol)
                        continue

                    # Pullback trigger check
                    is_triggered = False
                    if data["direction"] == "BUY" and live_price <= data["target_price"]: is_triggered = True
                    if data["direction"] == "SELL" and live_price >= data["target_price"]: is_triggered = True

                    if is_triggered:
                        logger.info(f"🎯 SNIPER TRIGGERED for {symbol} at {live_price:.5f}!")
                        await self._queue_execution_for_all(symbol, data["signal_data"], live_price)
                        symbols_to_remove.append(symbol)

                for sym in symbols_to_remove:
                    self.pending_sniper_entries.pop(sym, None)

            except Exception as e:
                logger.error(f"Sniper loop error: {e}")
            await asyncio.sleep(0.5)

    async def _queue_execution_for_all(self, symbol, signal_data, triggered_price):
        from models import Direction, AutopilotConfig
        # Gather eligible users and queue them
        direction = Direction(signal_data.get("direction"))
        all_configs_raw = await storage.get_all("autopilot_configs")
        
        for user_id, raw_cfg in all_configs_raw.items():
            try:
                cfg = AutopilotConfig.model_validate(raw_cfg)
                if not cfg.enabled or cfg.frozen: continue
                if cfg.daily_auto_trades_count >= 2: continue
                if symbol in cfg.open_auto_positions: continue
                
                await self._execution_queue.put({
                    "user_id": user_id,
                    "symbol": symbol,
                    "signal_data": signal_data,
                    "triggered_price": triggered_price,
                    "cfg": raw_cfg
                })
            except Exception as e:
                logger.error(f"Error queueing user {user_id}: {e}")

    async def _queue_worker(self):
        from models import Direction, AutopilotConfig
        import asyncio
        while self._running:
            try:
                task_data = await self._execution_queue.get()
                user_id = task_data["user_id"]
                symbol = task_data["symbol"]
                signal_data = task_data["signal_data"]
                triggered_price = task_data["triggered_price"]
                cfg = AutopilotConfig.model_validate(task_data["cfg"])
                
                # Check if system paused while in queue
                system_pause = await storage.get("system_state", "pause_flag")
                if system_pause:
                    self._execution_queue.task_done()
                    continue

                direction = Direction(signal_data.get("direction"))
                
                # Grab latest live price for the exact millisecond of execution killswitch check
                try:
                    from data_streamer import streamer
                    snapshot = streamer.get_latest_snapshot(symbol)
                    live_price = snapshot.ask if direction == Direction.BUY else snapshot.bid
                except Exception:
                    live_price = triggered_price # fallback
                
                # Stale Price Killswitch
                analysis_price = signal_data.get("current_price", 0.0)
                if not self._check_killswitch(analysis_price, live_price, symbol):
                    logger.warning(f"User {user_id}: Stale Price Killswitch triggered on {symbol}. Execution aborted.")
                    await self._log_to_morning_briefing(user_id, symbol, direction.value, "VETOED", "STALE_PRICE_SLIPPAGE")
                    self._execution_queue.task_done()
                    continue

                # Lock to prevent concurrent execution for this user
                lock_key = f"exec_{user_id}"
                acquired = await storage.acquire_lock(lock_key, ttl_seconds=30)
                if acquired:
                    try:
                        # Refresh config to make sure no other worker updated it
                        fresh_raw = await storage.get("autopilot_configs", user_id)
                        if fresh_raw:
                            fresh_cfg = AutopilotConfig.model_validate(fresh_raw)
                            if fresh_cfg.enabled and not fresh_cfg.frozen and symbol not in fresh_cfg.open_auto_positions:
                                await self._execute_for_user(user_id, fresh_cfg, symbol, direction, signal_data, live_price)
                    finally:
                        await storage.release_lock(lock_key)
                
                self._execution_queue.task_done()
            except Exception as e:
                logger.error(f"Queue worker error: {e}")

"""

code = code[:start_idx] + new_code_block + code[end_idx:]

# Remove _calculate_pullback_level entirely
cpb_start = code.find("    def _calculate_pullback_level")
cpb_end = code.find("    def _check_killswitch")
if cpb_start != -1 and cpb_end != -1:
    code = code[:cpb_start] + code[cpb_end:]

# Update _execute_for_user signature
old_sig = "    async def _execute_for_user(self, user_id: str, cfg: AutopilotConfig, symbol: str, direction: Direction, signal_data: dict):"
new_sig = "    async def _execute_for_user(self, user_id: str, cfg: AutopilotConfig, symbol: str, direction: Direction, signal_data: dict, live_price: float):"
code = code.replace(old_sig, new_sig)

code = code.replace('current_price = signal_data.get("current_price", 0.0)', 'current_price = live_price')

with open(r"c:\Mehd ai\mehd-ai\backend\auto_execution_worker.py", "w", encoding="utf-8") as f:
    f.write(code)

print("Refactored auto_execution_worker.py successfully.")
