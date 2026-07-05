"""
Mehd AI — Risk Gateway Tests
================================
Proves that the RiskGateway seal detection + 4-gate pipeline works.
Run with: python -m pytest tests/test_risk_gateway.py -v
"""

import pytest
import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from risk_engine import HardRiskKernel
from risk_gateway import RiskGateway, SealedRiskParameters
from models import TradeOrder, Direction


# ──────────────────────────────────────────────
#  FIXTURES
# ──────────────────────────────────────────────

@pytest.fixture
def anyio_backend():
    return 'asyncio'


@pytest.fixture
def kernel():
    from risk_state_store import RiskStateStore
    if os.path.exists(RiskStateStore._STATE_FILE):
        try:
            os.remove(RiskStateStore._STATE_FILE)
        except Exception:
            pass
    k = HardRiskKernel()
    yield k
    if os.path.exists(RiskStateStore._STATE_FILE):
        try:
            os.remove(RiskStateStore._STATE_FILE)
        except Exception:
            pass


@pytest.fixture
def gateway(kernel):
    return RiskGateway(kernel)


@pytest.fixture
def valid_order():
    return TradeOrder(
        symbol="EURUSD",
        direction=Direction.BUY,
        lot_size=0.1,
        stop_loss=1.0800,
        take_profit=1.0950,
    )


# ──────────────────────────────────────────────
#  TEST 1: Seal Integrity
# ──────────────────────────────────────────────

class TestSealIntegrity:
    """The gateway must detect when risk parameters change after boot."""

    def test_fresh_gateway_is_sealed(self, gateway):
        """A new gateway should be sealed immediately."""
        status = gateway.get_gateway_status()
        assert status["status"] == "SEALED"

    def test_seal_hash_is_consistent(self, gateway):
        """Same parameters should always produce the same hash."""
        hash1 = gateway._sealed.seal_hash
        hash2 = gateway._sealed.seal_hash
        assert hash1 == hash2
        assert len(hash1) > 10  # Must be a real hash, not empty

    def test_tampered_params_detected(self, gateway, kernel):
        """Changing kernel params after boot should break the seal."""
        # Tamper with the kernel's max risk
        original = kernel.MAX_RISK_PER_TRADE_PCT
        kernel.MAX_RISK_PER_TRADE_PCT = 0.50  # 50% — insane

        # The gateway should detect this
        is_valid = gateway._verify_seal_integrity()
        assert is_valid is False

        # Restore
        kernel.MAX_RISK_PER_TRADE_PCT = original

    @pytest.mark.anyio
    async def test_tampered_gateway_blocks_trades(self, gateway, kernel, valid_order):
        """If seal is broken, ALL trades must be blocked."""
        kernel.MAX_RISK_PER_TRADE_PCT = 0.50  # Tamper

        result = await gateway.evaluate_and_execute(
            order=valid_order,
            current_price=1.0850,
            current_spread=1.5,
            user_id="test_user",
        )

        assert result["seal_valid"] is False
        assert result["decision"].approved is False

        # Restore
        kernel.MAX_RISK_PER_TRADE_PCT = 0.01


# ──────────────────────────────────────────────
#  TEST 2: 4-Gate Pipeline
# ──────────────────────────────────────────────

class TestFourGatePipeline:
    """Every trade must pass through all 4 gates."""

    @pytest.mark.anyio
    async def test_valid_trade_passes_all_gates(self, gateway, valid_order):
        """A normal, safe trade should pass through cleanly."""
        result = await gateway.evaluate_and_execute(
            order=valid_order,
            current_price=1.0850,
            current_spread=1.5,
            user_id="test_user",
        )
        assert result["seal_valid"] is True
        assert result["decision"].approved is True
        assert result["evaluation_id"] is not None

    @pytest.mark.anyio
    async def test_no_stop_loss_blocked_at_gate_2(self, gateway):
        """Missing SL should be caught by the HardRiskKernel (Gate 2)."""
        bad_order = TradeOrder(
            symbol="EURUSD",
            direction=Direction.BUY,
            lot_size=0.1,
            stop_loss=None,
        )
        result = await gateway.evaluate_and_execute(
            order=bad_order,
            current_price=1.0850,
            current_spread=1.5,
            user_id="test_user",
        )
        assert result["decision"].approved is False

    @pytest.mark.anyio
    async def test_wide_spread_blocked(self, gateway, valid_order):
        """8-pip spread should be blocked by volatility check."""
        result = await gateway.evaluate_and_execute(
            order=valid_order,
            current_price=1.0850,
            current_spread=8.0,  # Too wide
            user_id="test_user",
        )
        assert result["decision"].approved is False


# ──────────────────────────────────────────────
#  TEST 3: Executor Registration
# ──────────────────────────────────────────────

class TestExecutorRegistration:
    """Only one broker executor can ever be registered."""

    def test_register_executor(self, gateway):
        """Should accept a valid executor function."""
        async def mock_executor(order, decision):
            return True

        gateway.register_executor(mock_executor)
        # Should not raise

    def test_double_register_prevented(self, gateway):
        """Registering a second executor must be blocked."""
        async def exec1(order, decision):
            return True

        async def exec2(order, decision):
            return True

        gateway.register_executor(exec1)
        with pytest.raises(Exception):
            gateway.register_executor(exec2)
