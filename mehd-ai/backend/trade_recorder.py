import asyncio
import logging
import json
import uuid
from datetime import datetime, timezone, timedelta

from storage import storage
from models import AutopilotConfig
from post_mortem_agent import post_mortem
from broadcaster import broadcaster

logger = logging.getLogger("mehd.trade_recorder")

class TradeRecorder:
    def record_trade_loss(self, user_id: str, symbol: str = ""):
        """Legacy 1:1. Spawns the async loss recording task."""
        if user_id:
            asyncio.create_task(self._record_loss_async(user_id, symbol))

    def record_trade_close(self, user_id: str, symbol: str):
        """Legacy 1:1. Spawns the async close recording task."""
        asyncio.create_task(self._record_close_async(user_id, symbol))

    def record_master_trade_loss(self, symbol: str, profit_per_lot: float = 0.0):
        """Called when the Master block order hits SL. Distributes loss logic."""
        asyncio.create_task(self._record_master_loss_async(symbol, profit_per_lot))

    def record_master_trade_close(self, symbol: str, profit_per_lot: float = 0.0):
        """Called when Master block order hits TP or manual close."""
        asyncio.create_task(self._record_master_close_async(symbol, profit_per_lot))

    async def _record_master_loss_async(self, symbol: str, profit_per_lot: float):
        if profit_per_lot == 0.0:
            # Fallback proxy if webhook fails to supply dollar amount
            profit_per_lot = -300.0

        receipts = await storage.query("master_receipts", [("symbol", "==", symbol), ("is_closed", "==", False)])
        for rid, rdata in receipts.items():
            rdata["is_closed"] = True
            rdata["profit_per_lot"] = profit_per_lot
            await storage.set("master_receipts", rid, rdata)
        
        async for chunk in storage.stream_collection("autopilot_configs", chunk_size=5000):
            save_tasks = []
            for user_id, raw_cfg in chunk.items():
                try:
                    cfg = AutopilotConfig.model_validate(raw_cfg)
                    modified = False
                    if symbol in cfg.open_auto_positions:
                        cfg.open_auto_positions.remove(symbol)
                        modified = True
                    
                    if modified:
                        cfg.last_losing_trade_timestamp = datetime.now(timezone.utc)
                        cfg.consecutive_losses += 1
                        cfg.consecutive_wins = 0
                        
                        if cfg.compounding_mode in ("DYNAMIC SCALING", "INSTITUTIONAL COMPOUNDING", "SNOWBALL", "LAMBO"):
                            allocated_lot = cfg.active_allocations.get(symbol, cfg.preferred_lot_size)
                            user_loss = abs(profit_per_lot) * allocated_lot
                            cfg.simulated_equity -= user_loss
                            
                            if cfg.peak_equity > 0:
                                cfg.current_drawdown_pct = ((cfg.peak_equity - cfg.simulated_equity) / cfg.peak_equity) * 100.0
                                
                        if symbol in cfg.active_allocations:
                            del cfg.active_allocations[symbol]

                        # Cleanup user positions state
                        asyncio.create_task(storage.delete("user_positions", f"{user_id}_{symbol}"))
                        save_tasks.append(self._save_config(user_id, cfg))
                except Exception as e:
                    logger.warning(f"Loss recording skipped user {user_id} on {symbol}: {e}")
            
            if save_tasks:
                await asyncio.gather(*save_tasks)

    async def _record_master_close_async(self, symbol: str, profit_per_lot: float):
        if profit_per_lot == 0.0:
            # Fallback proxy if webhook fails to supply dollar amount
            profit_per_lot = 600.0

        receipts = await storage.query("master_receipts", [("symbol", "==", symbol), ("is_closed", "==", False)])
        for rid, rdata in receipts.items():
            rdata["is_closed"] = True
            rdata["profit_per_lot"] = profit_per_lot
            await storage.set("master_receipts", rid, rdata)
                
        async for chunk in storage.stream_collection("autopilot_configs", chunk_size=5000):
            save_tasks = []
            for user_id, raw_cfg in chunk.items():
                try:
                    cfg = AutopilotConfig.model_validate(raw_cfg)
                    modified = False
                    if symbol in cfg.open_auto_positions:
                        cfg.open_auto_positions.remove(symbol)
                        modified = True
                        
                    if modified:
                        cfg.consecutive_wins += 1
                        cfg.consecutive_losses = 0
                        
                        if cfg.compounding_mode in ("DYNAMIC SCALING", "INSTITUTIONAL COMPOUNDING", "SNOWBALL", "LAMBO"):
                            allocated_lot = cfg.active_allocations.get(symbol, cfg.preferred_lot_size)
                            user_profit = profit_per_lot * allocated_lot
                            cfg.simulated_equity += user_profit
                            
                            if cfg.simulated_equity > cfg.peak_equity:
                                cfg.peak_equity = cfg.simulated_equity
                                cfg.current_drawdown_pct = 0.0
                            elif cfg.peak_equity > 0:
                                cfg.current_drawdown_pct = ((cfg.peak_equity - cfg.simulated_equity) / cfg.peak_equity) * 100.0
                                
                        if symbol in cfg.active_allocations:
                            del cfg.active_allocations[symbol]

                        # Cleanup user positions state
                        asyncio.create_task(storage.delete("user_positions", f"{user_id}_{symbol}"))
                        save_tasks.append(self._save_config(user_id, cfg))
                except Exception as e:
                    logger.warning(f"Close recording skipped user {user_id} on {symbol}: {e}")
            
            if save_tasks:
                await asyncio.gather(*save_tasks)

    async def _record_loss_async(self, user_id: str, symbol: str):
        lock_key = f"exec_{user_id}"
        acquired = await storage.acquire_lock(lock_key, ttl_seconds=30)
        if not acquired:
            await asyncio.sleep(1.0)
            acquired = await storage.acquire_lock(lock_key, ttl_seconds=30)
            if not acquired:
                logger.error("[ATOMIC] Could not acquire lock for loss record on %s. Aborting.", user_id)
                return
        try:
            raw = await storage.get("autopilot_configs", user_id)
            if not raw:
                return
            cfg = AutopilotConfig.model_validate(raw)
            cfg.last_losing_trade_timestamp = datetime.now(timezone.utc)
            if symbol and symbol in cfg.open_auto_positions:
                cfg.open_auto_positions.remove(symbol)
            await self._save_config(user_id, cfg)
            logger.info(f"User {user_id} entered 4-hour penalty box after trade loss on {symbol}.")
            
            # Post-mortem analysis trigger
            entry_signal = await storage.get("entry_snapshots", f"{user_id}_{symbol}")
            if not entry_signal:
                logger.warning(f"No entry snapshot found for {user_id} {symbol}. Post-mortem will use degraded fallback.")
                entry_signal = broadcaster.get_latest_signal(symbol) or {}
                
            direction = entry_signal.get("direction", "BUY")
            consensus = entry_signal.get("consensus", 85.0)
            snapshot_dump = json.dumps(entry_signal.get("snapshot", {}))
            
            asyncio.create_task(
                post_mortem.analyze_loss(
                    symbol=symbol,
                    direction=direction,
                    snapshot_dump=snapshot_dump,
                    original_consensus=consensus
                )
            )
            logger.info(f"🤖 Dispatched autonomous learning agent for lost trade on {symbol}.")
            await storage.delete("entry_snapshots", f"{user_id}_{symbol}")
            
        except Exception as e:
            logger.error(f"Failed to record trade loss for {user_id}: {e}")
        finally:
            await storage.release_lock(lock_key)

    async def _record_close_async(self, user_id: str, symbol: str):
        lock_key = f"exec_{user_id}"
        acquired = await storage.acquire_lock(lock_key, ttl_seconds=30)
        if not acquired:
            await asyncio.sleep(1.0)
            acquired = await storage.acquire_lock(lock_key, ttl_seconds=30)
            if not acquired:
                logger.error("[ATOMIC] Could not acquire lock for close record on %s. Aborting.", user_id)
                return
        try:
            raw = await storage.get("autopilot_configs", user_id)
            if not raw:
                return
            cfg = AutopilotConfig.model_validate(raw)
            if symbol in cfg.open_auto_positions:
                cfg.open_auto_positions.remove(symbol)
                await self._save_config(user_id, cfg)
                logger.info(f"User {user_id} auto-position on {symbol} closed and tracked.")
            
            await storage.delete("entry_snapshots", f"{user_id}_{symbol}")
            
        except Exception as e:
            logger.error(f"Failed to record trade close for {user_id}: {e}")
        finally:
            await storage.release_lock(lock_key)

    async def _save_config(self, user_id: str, cfg: AutopilotConfig):
        await storage.set("autopilot_configs", user_id, json.loads(cfg.model_dump_json()))

    async def _log_to_morning_briefing(self, user_id: str, symbol: str, direction: str, status: str, reason: str):
        log_entry = {
            "user_id": user_id,
            "symbol": symbol,
            "direction": direction,
            "status": status,
            "reason": reason,
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "expires_at": (datetime.now(timezone.utc) + timedelta(hours=24)).isoformat()
        }
        key = f"{user_id}_{uuid.uuid4()}"
        await storage.set("morning_briefing_logs", key, log_entry)

trade_recorder = TradeRecorder()
