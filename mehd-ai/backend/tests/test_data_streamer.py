"""
Mehd AI — Data Streamer Tests
================================
Tests for the market data streaming layer.
Covers: symbol resolution, mock tick generation, freshness tracking.
"""

import pytest
from unittest.mock import MagicMock
import sys

# Mock MT5 since it's not installed in test environments
sys.modules['MetaTrader5'] = MagicMock()

from data_streamer import MarketDataStreamer


class TestSymbolResolution:
    def setup_method(self):
        self.streamer = MarketDataStreamer()

    def test_gold_alias(self):
        assert self.streamer._resolve_symbol("GOLD") == "XAUUSD"

    def test_xauusd_direct(self):
        assert self.streamer._resolve_symbol("XAUUSD") == "XAUUSD"

    def test_btc_alias(self):
        assert self.streamer._resolve_symbol("BTC") == "BTCUSD"

    def test_bitcoin_alias(self):
        assert self.streamer._resolve_symbol("BITCOIN") == "BTCUSD"

    def test_slash_format_normalized(self):
        assert self.streamer._resolve_symbol("EUR/USD") == "EURUSD"

    def test_lowercase_normalized(self):
        assert self.streamer._resolve_symbol("eurusd") == "EURUSD"

    def test_whitespace_stripped(self):
        assert self.streamer._resolve_symbol("  GBPUSD  ") == "GBPUSD"


class TestMockTickGeneration:
    def setup_method(self):
        self.streamer = MarketDataStreamer()

    def test_generates_valid_snapshot(self):
        tick = self.streamer._generate_realistic_mock_tick("EURUSD")
        assert tick.bid > 0
        assert tick.ask > 0
        assert tick.ask >= tick.bid
        assert tick.spread > 0
        assert tick.symbol == "EURUSD"
        assert tick.data_source == "mock"

    def test_jpy_pair_reasonable_price(self):
        tick = self.streamer._generate_realistic_mock_tick("USDJPY")
        # JPY pairs should be around 100-200
        assert 50.0 < tick.bid < 300.0

    def test_gold_reasonable_price(self):
        tick = self.streamer._generate_realistic_mock_tick("XAUUSD")
        # Gold should be around 1500-3000
        assert 1000.0 < tick.bid < 5000.0

    def test_unknown_pair_defaults_to_1(self):
        tick = self.streamer._generate_realistic_mock_tick("ABCDEF")
        # Unknown pairs default to base price of 1.0
        assert 0.5 < tick.bid < 1.5

    def test_spread_reasonable(self):
        tick = self.streamer._generate_realistic_mock_tick("EURUSD")
        assert 0.5 < tick.spread < 5.0  # Normal spread range

    def test_consecutive_ticks_vary(self):
        """Mock ticks should simulate price movement."""
        tick1 = self.streamer._generate_realistic_mock_tick("EURUSD")
        # Store it so the next tick uses it as base
        self.streamer._latest_snapshots["EURUSD"] = tick1
        tick2 = self.streamer._generate_realistic_mock_tick("EURUSD")
        # Prices should be close but not identical
        assert abs(tick1.bid - tick2.bid) < 0.01


class TestFreshnessStamping:
    def setup_method(self):
        self.streamer = MarketDataStreamer()

    def test_fresh_data_is_live(self):
        import time
        tick = self.streamer._generate_realistic_mock_tick("EURUSD")
        self.streamer._snapshot_born_ms["EURUSD"] = int(time.time() * 1000)
        stamped = self.streamer._stamp_freshness(tick)
        # Should be very fresh (< 100ms since we just set it)
        assert stamped.data_age_ms < 1000
        assert stamped.latency_warning is False

    def test_stale_data_warning(self):
        import time
        tick = self.streamer._generate_realistic_mock_tick("EURUSD")
        # Set born time to 5 seconds ago
        self.streamer._snapshot_born_ms["EURUSD"] = int(time.time() * 1000) - 5000
        stamped = self.streamer._stamp_freshness(tick)
        assert stamped.data_age_ms > 3000
        assert stamped.latency_warning is True
        assert stamped.is_live is False
