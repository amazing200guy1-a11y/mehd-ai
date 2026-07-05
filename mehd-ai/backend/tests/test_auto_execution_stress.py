import asyncio
import logging
from datetime import datetime, timezone, timedelta
import uuid
import sys
import os

# Add parent directory to path to allow imports from backend
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from storage import storage
from models import AutopilotConfig, Direction, RiskDecision, TradeOrder
from auto_execution_worker import auto_execution_worker

logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")
logger = logging.getLogger("mehd.stress_test")

class AutoExecutionStressTest:
    """
    Stress tests the Mehd AI Auto-Execution Engine against ALL failure modes.
    """
    def __init__(self):
        self.results = []
        self.user_counter = 0

    def _generate_user_id(self):
        self.user_counter += 1
        return f"stress_user_{self.user_counter}"

    async def _setup_baseline_config(self, user_id):
        """Creates a baseline valid AutopilotConfig."""
        now = datetime.now(timezone.utc)
        cfg = AutopilotConfig(
            user_id=user_id,
            enabled=True,
            frozen=False,
            whitelisted_pairs=["EURUSD", "XAUUSD"],
            active_hours_start_utc=0,
            active_hours_end_utc=23,
            daily_auto_trades_count=0,
            weekly_auto_trades_count=0,
            last_trade_date=now.strftime("%Y-%m-%d"),
            last_losing_trade_timestamp=None,
            open_auto_positions=[],
            max_risk_per_trade_pct=1.0,
        )
        await storage.set("autopilot_configs", user_id, cfg.model_dump(mode="json"))
        return cfg

    async def _setup_pending_signal(self, sig_id, **overrides):
        """Creates a pending signal with defaults."""
        now = datetime.now(timezone.utc)
        signal = {
            "symbol": "EURUSD",
            "direction": "BUY",
            "broadcast_time": now.isoformat(),
            "consensus_pct": 95,
            "current_price": 1.1000,
            "suggested_sl": 1.0950,
            "suggested_tp": 1.1100,
            "votes": []
        }
        signal.update(overrides)
        await storage.set("pending_auto_executions", sig_id, signal)

    async def _run_and_capture_logs(self, test_name, user_id, sig_id):
        """Runs the worker logic for pending signals and captures the morning briefing."""
        print(f"\n[!] Running Test: {test_name}")
        
        # We call the internal method directly to process one loop
        await auto_execution_worker._process_pending_signals()
        
        # Check morning briefing for this user
        briefings = await storage.get_all("morning_briefing_logs")
        
        user_briefings = [b for b in briefings.values() if b["user_id"] == user_id]
        
        if not user_briefings:
            # Maybe the signal was discarded entirely (e.g. stale or olympus anomaly)
            print(f"Result: DISCARDED OR SILENTLY SKIPPED")
            self.results.append({"test": test_name, "status": "SKIPPED/DISCARDED"})
        else:
            latest = sorted(user_briefings, key=lambda x: x["timestamp"])[-1]
            print(f"Result: {latest['status']} - {latest['reason']}")
            self.results.append({"test": test_name, "status": latest["status"], "reason": latest["reason"]})

    async def test_1_stale_signal(self):
        # ── FIX P0 #2: SIGNAL FRESHNESS GATE ──
        user_id = self._generate_user_id()
        await self._setup_baseline_config(user_id)
        
        sig_id = str(uuid.uuid4())
        old_time = datetime.now(timezone.utc) - timedelta(minutes=10)
        await self._setup_pending_signal(sig_id, broadcast_time=old_time.isoformat())
        
        await self._run_and_capture_logs("Failure Mode 1: Stale Signal (>5m)", user_id, sig_id)

    async def test_2_olympus_anomaly(self):
        # ── FIX P1 #1: OLYMPUS ANOMALY FLAG CHECK ──
        user_id = self._generate_user_id()
        await self._setup_baseline_config(user_id)
        
        sig_id = str(uuid.uuid4())
        votes = [
            {"layer": "OLYMPUS", "reasoning": "flash crash detected"},
            {"layer": "OLYMPUS", "reasoning": "volatility spike imminent"}
        ]
        await self._setup_pending_signal(sig_id, votes=votes)
        
        await self._run_and_capture_logs("Failure Mode 2: Olympus Math Anomalies", user_id, sig_id)

    async def test_3_user_frozen(self):
        user_id = self._generate_user_id()
        cfg = await self._setup_baseline_config(user_id)
        cfg.frozen = True
        await storage.set("autopilot_configs", user_id, cfg.model_dump(mode="json"))
        
        sig_id = str(uuid.uuid4())
        await self._setup_pending_signal(sig_id)
        
        await self._run_and_capture_logs("Failure Mode 3: User Account Frozen", user_id, sig_id)

    async def test_4_whitelist_exclusion(self):
        user_id = self._generate_user_id()
        await self._setup_baseline_config(user_id)
        
        sig_id = str(uuid.uuid4())
        await self._setup_pending_signal(sig_id, symbol="GBPUSD") # Not in EURUSD, XAUUSD whitelist
        
        await self._run_and_capture_logs("Failure Mode 4: Symbol Not Whitelisted", user_id, sig_id)

    async def test_5_daily_limit_exceeded(self):
        user_id = self._generate_user_id()
        cfg = await self._setup_baseline_config(user_id)
        cfg.daily_auto_trades_count = 2 # Max is 2
        await storage.set("autopilot_configs", user_id, cfg.model_dump(mode="json"))
        
        sig_id = str(uuid.uuid4())
        await self._setup_pending_signal(sig_id)
        
        await self._run_and_capture_logs("Failure Mode 5: Daily Limit Exceeded", user_id, sig_id)

    async def test_6_four_hour_cooldown(self):
        user_id = self._generate_user_id()
        cfg = await self._setup_baseline_config(user_id)
        # Loss happened 2 hours ago
        cfg.last_losing_trade_timestamp = datetime.now(timezone.utc) - timedelta(hours=2)
        await storage.set("autopilot_configs", user_id, cfg.model_dump(mode="json"))
        
        sig_id = str(uuid.uuid4())
        await self._setup_pending_signal(sig_id)
        
        await self._run_and_capture_logs("Failure Mode 6: 4-Hour Post-Loss Cooldown", user_id, sig_id)

    async def test_7_duplicate_position(self):
        user_id = self._generate_user_id()
        cfg = await self._setup_baseline_config(user_id)
        cfg.open_auto_positions = ["EURUSD"]
        await storage.set("autopilot_configs", user_id, cfg.model_dump(mode="json"))
        
        sig_id = str(uuid.uuid4())
        await self._setup_pending_signal(sig_id, symbol="EURUSD")
        
        await self._run_and_capture_logs("Failure Mode 7: Duplicate Open Position", user_id, sig_id)

    async def run_all(self):
        print("==================================================")
        print(" MEHD AI - AUTO-EXECUTION STRESS TEST (FAILURE MODES)")
        print("==================================================")
        
        # Clear storage for testing isolation
        storage.data = {}
        
        await self.test_1_stale_signal()
        await self.test_2_olympus_anomaly()
        await self.test_3_user_frozen()
        await self.test_4_whitelist_exclusion()
        await self.test_5_daily_limit_exceeded()
        await self.test_6_four_hour_cooldown()
        await self.test_7_duplicate_position()

        # To test Risk Kernel VETO, Broker Timeout, and Broker Rejection, we would
        # need to patch/mock the broker gateway and risk kernel. 
        # I will add mocks for those to complete the "Every failure mode" requirement.

        await self.test_8_risk_kernel_veto()
        await self.test_9_broker_timeout()
        await self.test_10_broker_rejection()
        await self.test_11_successful_execution()
        
        print("\n==================================================")
        print(" STRESS TEST RESULTS")
        print("==================================================")
        for r in self.results:
            print(f"{r['test']:<45} | {r['status']}")

    async def test_8_risk_kernel_veto(self):
        import unittest.mock as mock
        user_id = self._generate_user_id()
        await self._setup_baseline_config(user_id)
        
        sig_id = str(uuid.uuid4())
        await self._setup_pending_signal(sig_id)

        # Mock RiskKernel to VETO
        with mock.patch("risk_engine.HardRiskKernel.evaluate") as mock_eval:
            mock_eval.return_value = RiskDecision(approved=False, calculated_lot_size=0, stop_loss=1.0950, rejection_reason="Too much risk")
            await self._run_and_capture_logs("Failure Mode 8: Risk Kernel Veto", user_id, sig_id)

    async def test_9_broker_timeout(self):
        import unittest.mock as mock
        user_id = self._generate_user_id()
        await self._setup_baseline_config(user_id)
        
        sig_id = str(uuid.uuid4())
        await self._setup_pending_signal(sig_id)

        with mock.patch("risk_engine.HardRiskKernel.evaluate") as mock_eval:
            mock_eval.return_value = RiskDecision(approved=True, calculated_lot_size=1.0, stop_loss=1.0950)
            
            with mock.patch("broker_gateway.BrokerGateway.execute_order", side_effect=asyncio.TimeoutError("Timeout")):
                await self._run_and_capture_logs("Failure Mode 9: Broker Timeout (Freeze Protocol)", user_id, sig_id)

    async def test_10_broker_rejection(self):
        import unittest.mock as mock
        user_id = self._generate_user_id()
        await self._setup_baseline_config(user_id)
        
        sig_id = str(uuid.uuid4())
        await self._setup_pending_signal(sig_id)

        with mock.patch("risk_engine.HardRiskKernel.evaluate") as mock_eval:
            mock_eval.return_value = RiskDecision(approved=True, calculated_lot_size=1.0, stop_loss=1.0950)
            
            with mock.patch("broker_gateway.BrokerGateway.execute_order") as mock_exec:
                mock_exec.return_value = {"status": "rejected", "reason": "Insufficient Margin"}
                await self._run_and_capture_logs("Failure Mode 10: Broker Rejection (Penalty Box)", user_id, sig_id)

    async def test_11_successful_execution(self):
        import unittest.mock as mock
        user_id = self._generate_user_id()
        await self._setup_baseline_config(user_id)
        
        sig_id = str(uuid.uuid4())
        await self._setup_pending_signal(sig_id)

        with mock.patch("risk_engine.HardRiskKernel.evaluate") as mock_eval:
            mock_eval.return_value = RiskDecision(approved=True, calculated_lot_size=1.0, stop_loss=1.0950)
            
            with mock.patch("broker_gateway.BrokerGateway.execute_order") as mock_exec:
                mock_exec.return_value = {"status": "filled", "fill_price": 1.1001, "units": 100000, "mode": "live"}
                await self._run_and_capture_logs("Success Path: Complete Execution", user_id, sig_id)

if __name__ == "__main__":
    tester = AutoExecutionStressTest()
    asyncio.run(tester.run_all())
