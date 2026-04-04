"""
Mehd AI — Live Market Data Streamer (FIX 1: Real-Time Feed)
============================================================
Triple-redundancy feed: OANDA → Polygon → TwelveData → Mock.
Every snapshot tracks data_age_ms, data_source, is_live, latency_warning.
"""

from __future__ import annotations

import asyncio
import logging
import os
import random
import time
import uuid
from datetime import datetime, timezone
from typing import AsyncGenerator, Optional

import httpx
from models import MarketSnapshot

logger = logging.getLogger("mehd.data_streamer")

# Try to import MT5, but don't crash if it's missing
try:
    import MetaTrader5 as mt5
    MT5_AVAILABLE = True
except ImportError:
    MT5_AVAILABLE = False

# ──────────────────────────────────────────────
#  FIX 1: Provider Configuration
# ──────────────────────────────────────────────

OANDA_API_KEY = os.getenv("OANDA_API_KEY", "")
OANDA_ACCOUNT_ID = os.getenv("OANDA_ACCOUNT_ID", "")
POLYGON_API_KEY = os.getenv("POLYGON_API_KEY", "")
TWELVEDATA_API_KEY = os.getenv("TWELVEDATA_API_KEY", "")

# Provider priority (highest first)
PROVIDER_CHAIN = ["oanda", "polygon", "twelvedata", "mock"]

# Symbol mapping for each provider
OANDA_SYMBOL_MAP = {
    "EURUSD": "EUR_USD", "GBPUSD": "GBP_USD", "USDJPY": "USD_JPY",
    "AUDUSD": "AUD_USD", "USDCAD": "USD_CAD", "NZDUSD": "NZD_USD",
    "EURGBP": "EUR_GBP", "EURJPY": "EUR_JPY", "GBPJPY": "GBP_JPY",
    "XAUUSD": "XAU_USD",
}


class MarketDataStreamer:
    """
    Manages the live price feed with triple-redundancy.
    Now tracks data_source, data_age_ms, is_live, and latency_warning
    on every single snapshot so the frontend always knows what it's seeing.
    """

    def __init__(self) -> None:
        self._running: bool = False
        self._active_symbols: set[str] = set()
        self._latest_snapshots: dict[str, MarketSnapshot] = {}
        self._subscribers: dict[str, list[asyncio.Queue[MarketSnapshot]]] = {}
        self._task: Optional[asyncio.Task] = None
        self.mt5_connected: bool = False
        self._active_provider: str = "mock"
        self._http_client: Optional[httpx.AsyncClient] = None
        # Track when each snapshot was born (epoch ms)
        self._snapshot_born_ms: dict[str, int] = {}

    async def start(self) -> None:
        if self._running:
            return
        logger.info("Initializing MarketDataStreamer...")

        self._http_client = httpx.AsyncClient(timeout=5.0)

        # 1. Try MT5
        if MT5_AVAILABLE:
            try:
                if mt5.initialize():
                    self.mt5_connected = True
                    self._active_provider = "mt5"
                    logger.info("Connected to MetaTrader 5 terminal.")
            except Exception:
                logger.warning("MT5 initialize() failed.")
        
        # 2. Determine best available provider
        if not self.mt5_connected:
            self._active_provider = await self._detect_best_provider()
            logger.info("Active data provider: %s", self._active_provider)

        self._running = True
        self._task = asyncio.create_task(self._poll_prices_loop())
        logger.info("MarketDataStreamer started (provider: %s).", self._active_provider)

    async def _detect_best_provider(self) -> str:
        """Try each provider in order and return the first one that responds."""
        if OANDA_API_KEY and OANDA_ACCOUNT_ID:
            try:
                resp = await self._http_client.get(
                    f"https://api-fxtrade.oanda.com/v3/accounts/{OANDA_ACCOUNT_ID}/summary",
                    headers={"Authorization": f"Bearer {OANDA_API_KEY}"},
                )
                if resp.status_code == 200:
                    return "oanda"
            except Exception as e:
                logger.warning("OANDA probe failed: %s", e)

        if POLYGON_API_KEY:
            try:
                resp = await self._http_client.get(
                    f"https://api.polygon.io/v2/aggs/ticker/C:EURUSD/prev?apiKey={POLYGON_API_KEY}",
                )
                if resp.status_code == 200:
                    return "polygon"
            except Exception as e:
                logger.warning("Polygon probe failed: %s", e)

        if TWELVEDATA_API_KEY:
            try:
                resp = await self._http_client.get(
                    f"https://api.twelvedata.com/price?symbol=EUR/USD&apikey={TWELVEDATA_API_KEY}",
                )
                if resp.status_code == 200:
                    return "twelvedata"
            except Exception as e:
                logger.warning("TwelveData probe failed: %s", e)

        return "mock"

    async def stop(self) -> None:
        self._running = False
        if self._task:
            self._task.cancel()
            try:
                await self._task
            except asyncio.CancelledError:
                pass
        if self._http_client:
            await self._http_client.aclose()
        if self.mt5_connected and MT5_AVAILABLE:
            mt5.shutdown()
        logger.info("MarketDataStreamer stopped.")

    def _resolve_symbol(self, raw_symbol: str) -> str:
        s = raw_symbol.upper().strip()
        if s in ["GOLD", "XAUUSD"]:
            s = "XAUUSD"
        elif s in ["BTC", "BITCOIN"]:
            s = "BTCUSD"
        s = s.replace("/", "")
        return s

    async def subscribe(self, raw_symbol: str) -> AsyncGenerator[MarketSnapshot, None]:
        symbol = self._resolve_symbol(raw_symbol)
        self._active_symbols.add(symbol)
        queue: asyncio.Queue[MarketSnapshot] = asyncio.Queue(maxsize=100)
        if symbol not in self._subscribers:
            self._subscribers[symbol] = []
        self._subscribers[symbol].append(queue)
        logger.info("New subscriber for %s. Active symbols: %d", symbol, len(self._active_symbols))
        if symbol in self._latest_snapshots:
            yield self._latest_snapshots[symbol]
        try:
            while self._running:
                snapshot = await queue.get()
                yield snapshot
        except asyncio.CancelledError:
            pass
        finally:
            if symbol in self._subscribers and queue in self._subscribers[symbol]:
                self._subscribers[symbol].remove(queue)
                if not self._subscribers[symbol]:
                    self._active_symbols.discard(symbol)

    def get_latest_snapshot(self, raw_symbol: str) -> MarketSnapshot:
        symbol = self._resolve_symbol(raw_symbol)
        if symbol in self._latest_snapshots:
            snap = self._latest_snapshots[symbol]
            # Recompute freshness at access time
            return self._stamp_freshness(snap)
        return self._generate_realistic_mock_tick(symbol)

    def _stamp_freshness(self, snap: MarketSnapshot) -> MarketSnapshot:
        """Recalculates data_age_ms, is_live, latency_warning at serve time."""
        now_ms = int(time.time() * 1000)
        born_ms = self._snapshot_born_ms.get(snap.symbol, now_ms)
        age = now_ms - born_ms
        return snap.model_copy(update={
            "data_age_ms": age,
            "is_live": age < 1000,
            "latency_warning": age > 3000,
        })

    async def _poll_prices_loop(self) -> None:
        while self._running:
            if not self._active_symbols:
                await asyncio.sleep(0.5)
                continue

            for symbol in list(self._active_symbols):
                try:
                    snapshot = await self._fetch_with_fallback(symbol)
                    self._latest_snapshots[symbol] = snapshot
                    self._snapshot_born_ms[symbol] = int(time.time() * 1000)

                    if symbol in self._subscribers:
                        dead_queues = []
                        for q in self._subscribers[symbol]:
                            try:
                                if q.full():
                                    q.get_nowait()
                                q.put_nowait(self._stamp_freshness(snapshot))
                            except Exception:
                                dead_queues.append(q)
                        for dq in dead_queues:
                            self._subscribers[symbol].remove(dq)
                except Exception as e:
                    logger.error("Error fetching tick for %s: %s", symbol, e)

            await asyncio.sleep(0.1)  # 100ms tick rate

    async def _fetch_with_fallback(self, symbol: str) -> MarketSnapshot:
        """
        FIX 1 core: Tries providers in priority order.
        If the active one fails, cascades down the chain.
        """
        providers_to_try = [self._active_provider] + [
            p for p in PROVIDER_CHAIN if p != self._active_provider
        ]

        for provider in providers_to_try:
            try:
                if provider == "mt5" and self.mt5_connected and MT5_AVAILABLE:
                    return await self._fetch_mt5(symbol)
                elif provider == "oanda" and OANDA_API_KEY:
                    return await self._fetch_oanda(symbol)
                elif provider == "polygon" and POLYGON_API_KEY:
                    return await self._fetch_polygon(symbol)
                elif provider == "twelvedata" and TWELVEDATA_API_KEY:
                    return await self._fetch_twelvedata(symbol)
                elif provider == "mock":
                    return self._generate_realistic_mock_tick(symbol)
            except Exception as e:
                logger.warning("Provider '%s' failed for %s: %s — trying next", provider, symbol, e)
                continue

        # Absolute last resort
        return self._generate_realistic_mock_tick(symbol)

    async def _fetch_mt5(self, symbol: str) -> MarketSnapshot:
        loop = asyncio.get_running_loop()
        return await loop.run_in_executor(None, self._fetch_mt5_sync, symbol)

    def _fetch_mt5_sync(self, symbol: str) -> MarketSnapshot:
        tick = mt5.symbol_info_tick(symbol)
        info = mt5.symbol_info(symbol)
        if tick is None or info is None:
            raise ConnectionError(f"MT5 returned None for {symbol}")
        timestamp = datetime.fromtimestamp(tick.time, tz=timezone.utc)
        pip_multiplier = 10000 if info.digits == 5 else (100 if info.digits == 3 else 1)
        spread_pips = (tick.ask - tick.bid) * pip_multiplier
        return MarketSnapshot(
            symbol=symbol, bid=tick.bid, ask=tick.ask,
            spread=round(spread_pips, 1), timestamp=timestamp,
            open=tick.bid, high=tick.bid, low=tick.bid, close=tick.bid,
            volume=tick.volume, data_source="mt5", data_age_ms=0, is_live=True, latency_warning=False,
        )

    async def _fetch_oanda(self, symbol: str) -> MarketSnapshot:
        oanda_sym = OANDA_SYMBOL_MAP.get(symbol, symbol.replace("USD", "_USD"))
        resp = await self._http_client.get(
            f"https://api-fxtrade.oanda.com/v3/accounts/{OANDA_ACCOUNT_ID}/pricing?instruments={oanda_sym}",
            headers={"Authorization": f"Bearer {OANDA_API_KEY}"},
        )
        resp.raise_for_status()
        data = resp.json()
        price = data["prices"][0]
        bid = float(price["bids"][0]["price"])
        ask = float(price["asks"][0]["price"])
        pip_size = 0.01 if "JPY" in symbol else (0.1 if "XAU" in symbol else 0.0001)
        spread_pips = (ask - bid) / pip_size
        return MarketSnapshot(
            symbol=symbol, bid=bid, ask=ask, spread=round(spread_pips, 1),
            timestamp=datetime.now(timezone.utc), open=bid, high=bid, low=bid, close=bid,
            volume=0.0, data_source="oanda", data_age_ms=0, is_live=True, latency_warning=False,
        )

    async def _fetch_polygon(self, symbol: str) -> MarketSnapshot:
        resp = await self._http_client.get(
            f"https://api.polygon.io/v2/aggs/ticker/C:{symbol}/prev?apiKey={POLYGON_API_KEY}",
        )
        resp.raise_for_status()
        result = resp.json()["results"][0]
        bid = result["c"]
        ask = bid + 0.0002  # Polygon doesn't give B/A for forex on free tier
        pip_size = 0.01 if "JPY" in symbol else 0.0001
        return MarketSnapshot(
            symbol=symbol, bid=bid, ask=ask, spread=round((ask - bid) / pip_size, 1),
            timestamp=datetime.now(timezone.utc), open=result["o"], high=result["h"],
            low=result["l"], close=result["c"], volume=result.get("v", 0),
            data_source="polygon", data_age_ms=0, is_live=True, latency_warning=False,
        )

    async def _fetch_twelvedata(self, symbol: str) -> MarketSnapshot:
        fmt_symbol = f"{symbol[:3]}/{symbol[3:]}" if len(symbol) == 6 else symbol
        resp = await self._http_client.get(
            f"https://api.twelvedata.com/price?symbol={fmt_symbol}&apikey={TWELVEDATA_API_KEY}",
        )
        resp.raise_for_status()
        data = resp.json()
        price = float(data["price"])
        pip_size = 0.01 if "JPY" in symbol else 0.0001
        ask = price + (1.5 * pip_size)  # Approximate spread
        return MarketSnapshot(
            symbol=symbol, bid=price, ask=round(ask, 5), spread=1.5,
            timestamp=datetime.now(timezone.utc), open=price, high=price, low=price,
            close=price, volume=0.0, data_source="twelvedata",
            data_age_ms=0, is_live=True, latency_warning=False,
        )

    def _generate_realistic_mock_tick(self, symbol: str) -> MarketSnapshot:
        base_prices = {
            "EURUSD": 1.0850, "GBPUSD": 1.2650, "USDJPY": 150.20,
            "XAUUSD": 2040.50, "BTCUSD": 63400.00,
        }
        base = base_prices.get(symbol, 1.0000)
        if symbol in self._latest_snapshots:
            prev = self._latest_snapshots[symbol]
            change = prev.bid * random.uniform(-0.00005, 0.00005)
            new_bid = prev.bid + change
        else:
            new_bid = base

        multiplier = 0.01 if "JPY" in symbol else (0.1 if "XAU" in symbol else 0.0001)
        spread_pips = random.uniform(1.0, 2.5)
        new_ask = new_bid + (spread_pips * multiplier)

        return MarketSnapshot(
            id=uuid.uuid4(), symbol=symbol, bid=round(new_bid, 5), ask=round(new_ask, 5),
            spread=round(spread_pips, 1), timestamp=datetime.now(timezone.utc),
            open=round(base, 5), high=round(max(base, new_bid) + (20 * multiplier), 5),
            low=round(min(base, new_bid) - (20 * multiplier), 5), close=round(new_bid, 5),
            volume=random.uniform(10, 500),
            data_source="mock", data_age_ms=0, is_live=False, latency_warning=False,
        )
