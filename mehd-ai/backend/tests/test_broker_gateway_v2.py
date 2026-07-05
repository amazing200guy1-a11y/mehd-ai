"""
Mehd AI — Broker Gateway Tests
=================================
Tests for the OANDA broker integration layer.
Covers: paper mode, symbol mapping, lot conversion, account summary.
"""

import pytest
from unittest.mock import patch, MagicMock

from models import TradeOrder, RiskDecision, Direction
from broker_gateway import (
    BrokerGateway,
    _get_oanda_instrument,
    _lot_to_units,
)


# ──────────────────────────────────────────────
#  Symbol Mapping Tests
# ──────────────────────────────────────────────

class TestSymbolMapping:
    def test_eurusd(self):
        assert _get_oanda_instrument("EURUSD") == "EUR_USD"

    def test_gbpusd(self):
        assert _get_oanda_instrument("GBPUSD") == "GBP_USD"

    def test_usdjpy(self):
        assert _get_oanda_instrument("USDJPY") == "USD_JPY"

    def test_xauusd(self):
        assert _get_oanda_instrument("XAUUSD") == "XAU_USD"

    def test_case_insensitive(self):
        assert _get_oanda_instrument("eurusd") == "EUR_USD"

    def test_unknown_symbol_fallback(self):
        """Unknown symbols should still get a reasonable conversion."""
        result = _get_oanda_instrument("NZDUSD")
        assert result == "NZD_USD"


# ──────────────────────────────────────────────
#  Lot to Units Conversion
# ──────────────────────────────────────────────

class TestLotToUnits:
    def test_one_standard_lot(self):
        """1 lot = 100,000 units for forex."""
        assert _lot_to_units(1.0, "EURUSD") == 100_000

    def test_micro_lot(self):
        """0.01 lot = 1,000 units."""
        assert _lot_to_units(0.01, "EURUSD") == 1_000

    def test_mini_lot(self):
        """0.10 lot = 10,000 units."""
        assert _lot_to_units(0.10, "EURUSD") == 10_000

    def test_gold_lot(self):
        """Gold: 1 lot = 100 unit (ounce)."""
        assert _lot_to_units(1.0, "XAUUSD") == 100

    def test_fractional_lot(self):
        """0.69 lots = 69,000 units."""
        assert _lot_to_units(0.69, "GBPUSD") == 69_000


# ──────────────────────────────────────────────
#  Paper Mode Tests
# ──────────────────────────────────────────────

class TestPaperMode:
    def setup_method(self):
        """Create a gateway with no API keys (paper mode)."""
        with patch.dict("os.environ", {"OANDA_API_KEY": "", "OANDA_ACCOUNT_ID": ""}):
            self.gw = BrokerGateway()

    def test_is_paper_mode(self):
        assert not self.gw._is_live

    def test_paper_execution_returns_simulated(self):
        order = TradeOrder(
            symbol="EURUSD",
            direction=Direction.BUY,
            lot_size=0.01,
            stop_loss=1.08000,
            take_profit=1.09000,
        )
        decision = RiskDecision(
            approved=True,
            calculated_lot_size=0.01,
            stop_loss=1.08000,
            take_profit=1.09000,
        )
        import asyncio
        result = asyncio.run(self.gw.execute_order(order, decision))
        assert result["mode"] == "paper"
        assert result["status"] == "simulated"
        assert result["broker"] == "mock"

    def test_paper_account_summary(self):
        import asyncio
        summary = asyncio.run(self.gw.get_account_summary())
        assert summary["mode"] == "paper"
        assert summary["balance"] == 10_000.0
        assert summary["equity"] == 10_000.0
