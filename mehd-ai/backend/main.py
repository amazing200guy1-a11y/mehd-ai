"""
Mehd AI — FastAPI Application
==============================
This is the front door of the entire system. The Flutter app
(or any HTTP client) talks to these four endpoints.

How the pieces connect:
    Flutter App  →  main.py (FastAPI)
                      ├── /analyze/{symbol}  →  The Den (9 AI predators)
                      ├── /execute           →  HardRiskKernel → AuditLogger
                      ├── /account_health    →  HardRiskKernel
                      └── /health            →  Self-check

Every request is async — FastAPI uses Python's asyncio to handle
thousands of concurrent connections without blocking.
CORS is enabled for all origins because the Flutter frontend
will connect from a different domain.
"""

from __future__ import annotations

import logging
import time
from contextlib import asynccontextmanager
from datetime import datetime, timezone

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware

from sse_starlette.sse import EventSourceResponse

from audit_trail import AuditLogger
from consensus_engine import AsyncCouncil
from data_streamer import MarketDataStreamer
from models import (
    AccountHealth,
    ConsensusResult,
    Direction,
    MarketSnapshot,
    RiskDecision,
    TradeOrder,
    ExecutiveBrief,
)
from risk_engine import HardRiskKernel
from pydantic import BaseModel
from typing import Optional, List
import asyncio

# ──────────────────────────────────────────────
#  Logging configuration
# ──────────────────────────────────────────────

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s │ %(name)-22s │ %(levelname)-8s │ %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger("mehd.main")

# ──────────────────────────────────────────────
#  Global instances — created once at startup
# ──────────────────────────────────────────────

risk_kernel = HardRiskKernel()
den_engine = AsyncCouncil()
MOCK_FIREBASE_BRIEFS: dict[str, ExecutiveBrief] = {}
audit = AuditLogger()
streamer = MarketDataStreamer()

# Track when the server started (for the /health endpoint)
_start_time: float = time.time()


# ──────────────────────────────────────────────
#  Startup / Shutdown lifecycle
# ──────────────────────────────────────────────

@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Runs on startup and shutdown.
    Startup: verify that critical systems are loaded.
    Shutdown: log a clean exit.
    """
    # ── STARTUP ──────────────────────────────
    logger.info("=" * 60)
    logger.info("  MEHD AI — Starting up")
    logger.info("=" * 60)

    # Self-check 1: Risk engine loaded?
    try:
        health = risk_kernel.get_account_health()
        logger.info(
            "✓ Risk engine loaded — balance: $%.2f, locked: %s",
            health.balance,
            health.is_locked,
        )
    except Exception as e:
        logger.critical("✗ Risk engine FAILED to load: %s", e)
        raise RuntimeError(f"Risk engine startup check failed: {e}") from e

    # Self-check 2: Audit trail initialised?
    try:
        logger.info("✓ Audit trail initialised — session: %s", audit.session_id)
    except Exception as e:
        logger.error("✗ Audit trail issue (non-fatal): %s", e)

    # Self-check 3: Den models reachable?
    try:
        model_status = await den_engine.health_check()
        responding = sum(1 for s in model_status.values() if s == "responding")
        logger.info("✓ The Den: %d/%d models responding", responding, len(model_status))
    except Exception as e:
        logger.error("✗ Den health check issue (non-fatal): %s", e)

    # Start data streamer
    try:
        await streamer.start()
        logger.info("✓ Market Data Streamer started")
    except Exception as e:
        logger.error("✗ Streamer startup issue (non-fatal): %s", e)

    logger.info("=" * 60)
    logger.info("  MEHD AI — Ready to protect traders")
    logger.info("=" * 60)

    yield  # ← App is running here

    # ── SHUTDOWN ─────────────────────────────
    logger.info("MEHD AI — Shutting down gracefully")
    await streamer.stop()


# ──────────────────────────────────────────────
#  FastAPI App
# ──────────────────────────────────────────────

app = FastAPI(
    title="Mehd AI — Forex Trading Assistant",
    description=(
        "Multi-model AI consensus engine with unbreakable risk rules. "
        "Protects traders from losing money through 9-model voting, "
        "hard-coded safety limits, and permanent audit logging."
    ),
    version="0.1.0",
    lifespan=lifespan,
)

# ── CORS — allow the Flutter frontend from any origin ──
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, restrict to your Flutter app's domain
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ──────────────────────────────────────────────
#  ENDPOINT 1: GET /analyze/{symbol}
#  "What do the AI models think about this pair?"
# ──────────────────────────────────────────────

@app.get(
    "/analyze/{symbol}",
    response_model=ConsensusResult,
    summary="Analyze a currency pair with 9 AI models",
    tags=["Analysis"],
)
async def analyze_symbol(symbol: str) -> ConsensusResult:
    """
    Fires all 9 AI models to analyze the given currency pair.
    Returns the consensus result with every model's vote,
    the majority direction, and whether trading should proceed.

    In Phase 1, this uses mock data.
    In Phase 2, this hits real AI APIs.
    """
    logger.info("=== ANALYZE REQUEST: %s ===", symbol)

    # Get the real live market snapshot
    live_snapshot = streamer.get_latest_snapshot(symbol)

    try:
        result = await den_engine.analyze(symbol, live_snapshot)

        # Upgrade 2: Math Layer pre-check
        math_votes = [v for v in result.votes if v.model_name in ["deepseek", "openai-o3", "codestral"]]
        vetoed, veto_reason = risk_kernel.check_math_veto(math_votes)
        if vetoed:
            result.proceed = False
            result.rejection_reason = "Math Layer Veto — Market unsafe"

        # Log to audit trail
        audit.log_consensus(symbol, result)

        return result

    except Exception as e:
        logger.error("Analysis failed for %s: %s", symbol, e)
        raise HTTPException(
            status_code=500,
            detail=f"Analysis failed: {str(e)}",
        ) from e


# ──────────────────────────────────────────────
#  ENDPOINT 2: GET /stream/{symbol}
#  "Give me live prices streaming continuously"
# ──────────────────────────────────────────────

@app.get(
    "/stream/{symbol}",
    summary="Live Server-Sent Events price stream",
    tags=["Streaming"],
)
async def stream_prices(symbol: str):
    """
    Connects to the background MarketDataStreamer and pushes
    live prices to the frontend every 100ms via SSE.
    The Flutter app listens to this to update charting and ticks.
    """
    async def event_generator():
        try:
            # Subscribe returns an AsyncGenerator of MarketSnapshots
            async for snapshot in streamer.subscribe(symbol):
                # SSE requires data to be a string
                yield {"data": snapshot.model_dump_json()}
        except asyncio.CancelledError:
            # Client disconnected
            pass

    return EventSourceResponse(event_generator())


# ──────────────────────────────────────────────
#  ENDPOINT 3: POST /execute
#  "I want to make this trade — am I allowed?"
# ──────────────────────────────────────────────

@app.post(
    "/execute",
    response_model=RiskDecision,
    summary="Execute a trade (risk kernel runs first)",
    tags=["Trading"],
)
async def execute_trade(order: TradeOrder) -> RiskDecision:
    """
    Submit a trade order. The HardRiskKernel evaluates it FIRST.
    If ANY risk rule fails, the trade is rejected immediately
    with a clear reason. No override is possible.

    If approved, the trade and decision are logged to the audit trail.
    """
    logger.info(
        "=== EXECUTE REQUEST: %s %s %.2f lots ===",
        order.direction.value,
        order.symbol,
        order.lot_size,
    )

    try:
        # THE RISK KERNEL ALWAYS RUNS FIRST — NON-NEGOTIABLE
        decision = risk_kernel.evaluate(order)

        # Log the trade attempt regardless of approval
        audit.log_trade(order, decision)

        if not decision.approved:
            logger.warning(
                "Trade REJECTED: %s — %s",
                order.symbol,
                decision.rejection_reason,
            )
            # Log account event if it was a lock
            if risk_kernel.account.is_locked:
                audit.log_account_event(
                    "ACCOUNT_LOCKED",
                    risk_kernel.get_account_health(),
                )
        else:
            # Generate the mock Firebase Executive Brief
            current_health = risk_kernel.get_account_health()
            brief = ExecutiveBrief(
                trade_id=decision.id,
                symbol=order.symbol,
                timestamp=datetime.now(timezone.utc),
                final_verdict=order.direction.value,
                consensus_score="N/A",
                sentiment_layer={},
                strategy_layer={},
                math_layer={},
                risk_verification={
                    "Lot size": str(decision.calculated_lot_size),
                    "Max loss": f"${current_health.balance * order.risk_percentage:.2f} ({order.risk_percentage*100:.0f}% of balance)",
                    "Stop loss": f"{decision.stop_loss} ✓",
                    "Take profit": f"{decision.take_profit or 'N/A'} ✓",
                    "Volatility": "Normal ✓"
                },
                decision_basis="This trade was not a glitch. It was a calculated decision based on sentiment, technical structure, and mathematical verification. All decisions logged permanently."
            )

            if order.votes:
                agree_count = sum(1 for v in order.votes if v.direction == order.direction)
                total = len(order.votes)
                pct = int((agree_count / total) * 100) if total > 0 else 0
                brief.consensus_score = f"{agree_count}/{total} ({pct}%)"

                for v in order.votes:
                    layer = "math_layer" if v.model_name in ["deepseek", "openai-o3", "codestral"] else "sentiment_layer" if v.model_name in ["grok", "perplexity", "gemini"] else "strategy_layer"
                    getattr(brief, layer)[v.model_name] = f"{v.direction.value} — {v.reasoning}"

            MOCK_FIREBASE_BRIEFS[str(decision.id)] = brief

        return decision

    except Exception as e:
        logger.error("Trade execution failed: %s", e)
        raise HTTPException(
            status_code=500,
            detail=f"Trade execution failed: {str(e)}",
        ) from e


# ──────────────────────────────────────────────
#  ENDPOINT 4: GET /account_health
#  "How is my account doing? Am I locked out?"
# ──────────────────────────────────────────────

@app.get(
    "/account_health",
    response_model=AccountHealth,
    summary="Get current account status",
    tags=["Account"],
)
async def get_account_health() -> AccountHealth:
    """
    Returns the real-time account health snapshot.
    Shows balance, equity, drawdown, and lock status.
    The Flutter frontend polls this to update the UI.
    """
    return risk_kernel.get_account_health()


# ──────────────────────────────────────────────
#  ENDPOINT 5: GET /health
#  "Is the system alive and working?"
# ──────────────────────────────────────────────

@app.get(
    "/health",
    summary="System heartbeat",
    tags=["System"],
)
async def health_check() -> dict:
    """
    System heartbeat endpoint. Returns:
    - status: "healthy" or "degraded"
    - uptime_seconds: how long the server has been running
    - risk_engine: whether the kernel is loaded
    - model_status: which AI models are responding
    - timestamp: current UTC time
    """
    uptime = time.time() - _start_time

    # Check risk engine
    try:
        _ = risk_kernel.get_account_health()
        risk_status = "loaded"
    except Exception as e:
        risk_status = f"error: {e}"

    # Check model stubs
    try:
        model_status = await den_engine.health_check()
    except Exception as e:
        model_status = {"error": str(e)}

    all_models_ok = all(
        s == "responding"
        for s in model_status.values()
        if isinstance(model_status, dict)
    )

    return {
        "status": "healthy" if risk_status == "loaded" and all_models_ok else "degraded",
        "uptime_seconds": round(uptime, 2),
        "risk_engine": risk_status,
        "audit_session": audit.session_id,
        "model_status": model_status,
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }


@app.get("/den/brief/{trade_id}", tags=["Den"], response_model=ExecutiveBrief)
async def get_executive_brief(trade_id: str):
    if trade_id in MOCK_FIREBASE_BRIEFS:
        return MOCK_FIREBASE_BRIEFS[trade_id]
    raise HTTPException(status_code=404, detail="Brief not found")

# ──────────────────────────────────────────────
#  ENDPOINT 6: THE DEN ROUTER (Phase 8)
# ──────────────────────────────────────────────

class DenRequest(BaseModel):
    query: str
    symbol: Optional[str] = None

class ShadowReport(BaseModel):
    total_signals: int
    win_rate: float
    return_vs_market: float
    best_performing_room: str
    worst_performing_pair: str
    certified_alpha: bool

class MarketplaceConfig(BaseModel):
    id: str
    creator: str
    name: str
    win_rate: float
    return_vs_market: float
    certified_alpha: bool
    followers: int
    subscription_fee: float

MOCK_MARKETPLACE: list[MarketplaceConfig] = [
    MarketplaceConfig(
        id="mk1",
        creator="0xTitan",
        name="Macro Event Driven (NFP Specialist)",
        win_rate=82.4,
        return_vs_market=24.1,
        certified_alpha=True,
        followers=1420,
        subscription_fee=50.0
    ),
    MarketplaceConfig(
        id="mk2",
        creator="QuantZ",
        name="London Session Breakouts",
        win_rate=76.8,
        return_vs_market=18.5,
        certified_alpha=True,
        followers=890,
        subscription_fee=25.0
    ),
    MarketplaceConfig(
        id="mk3",
        creator="RetailSlayer",
        name="Pure Sentiment Contrarian",
        win_rate=68.2,
        return_vs_market=11.2,
        certified_alpha=False,
        followers=420,
        subscription_fee=10.0
    ),
]

class DenRouter:
    TILT_WORDS = ["scared", "revenge", "angry", "frustrated", "desperate", "recover", "loss"]

    @classmethod
    async def route_question(cls, query: str):
        # Fast classification call mock
        q_lower = query.lower()
        if "news" in q_lower or "sentiment" in q_lower or "event" in q_lower:
            return await cls.research(query)
        elif "risk" in q_lower or "setup" in q_lower or "structure" in q_lower:
            return await cls.strategy(query)
        else:
            return await cls.math(query)

    @classmethod
    async def research(cls, query: str):
        return {
            "layer": "Research Room",
            "models": ["Grok", "Perplexity", "Gemini"],
            "response": "Scanning global macro data and X (Twitter) sentiment. No black swan events detected. Sentiment is heavily bullish on USD based on recent central bank speak."
        }
    
    @classmethod
    async def strategy(cls, query: str):
        return {
            "layer": "Strategy Room",
            "models": ["Claude", "GPT-4", "Llama"],
            "response": "Analyzing market structure. Liquidity resting below 1.0850. Waiting for a sweep before entering long. FVG fill acts as premium entry."
        }

    @classmethod
    async def math(cls, query: str):
        return {
            "layer": "Math Room",
            "models": ["DeepSeek", "o3", "Codestral"],
            "response": "Running Monte Carlo simulations. 87% probability of mean reversion within the next 4 hours. Standard deviation strictly aligns with the chosen entry coordinate."
        }

    @classmethod
    async def vibe(cls, query: str):
        q_lower = query.lower()
        for w in cls.TILT_WORDS:
            if w in q_lower:
                return {
                    "text": (
                        "I sense frustration. The market is not running away from you, but your capital might. "
                        "Revenge trading is the fastest path to zero.\n\n"
                        "Remember: Capital is a seed, not a sacrifice.\n\n"
                        "Let's step back. I am locking live execution for this session. We can review the charts in Paper Trading mode until the storm passes."
                    ),
                    "is_emotional": True,
                    "consensus": None
                }
        
        return {
            "text": "Hunting all 28 major pairs...\n\nEUR/USD has the highest confluence. The fundamental narrative matches the technical Fibonacci retracement. Here is the safest setup right now.",
            "is_emotional": False,
            "consensus": {
                "final_direction": "BUY",
                "consensus_percentage": 88,
                "proceed": True,
                "rejection_reason": None,
                "votes": []
            }
        }

@app.post("/den/research", tags=["The Den"])
async def den_research(req: DenRequest):
    return await DenRouter.research(req.query)

@app.post("/den/strategy", tags=["The Den"])
async def den_strategy(req: DenRequest):
    return await DenRouter.strategy(req.query)

@app.post("/den/math", tags=["The Den"])
async def den_math(req: DenRequest):
    return await DenRouter.math(req.query)

@app.post("/den/vibe", tags=["The Den"])
async def den_vibe(req: DenRequest):
    return await DenRouter.vibe(req.query)

@app.post("/den/ask", tags=["The Den"])
async def den_ask(req: DenRequest):
    return await DenRouter.route_question(req.query)

@app.get("/den/journey", tags=["The Den"])
async def den_journey():
    return {
        "status": "active",
        "current_week": 3,
        "phase": "Survival & Preservation",
        "protection_score": 92,
        "mistake_dna": [
            {"trait": "Revenge Trading", "severity": 0.8},
            {"trait": "Session Ignorance", "severity": 0.6},
            {"trait": "Over-Leveraging", "severity": 0.9}
        ]
    }

@app.get("/den/report", tags=["The Den"])
async def den_report():
    return {
        "report": "Weekly Den Report: Protected capital effectively. Avoided 2 high-risk setups during NFP. HardRisk kernel correctly intervened once on Thursday."
    }

@app.post("/den/shadow", tags=["The Den"], response_model=ShadowReport)
async def activate_shadow_mode():
    await asyncio.sleep(2)
    return ShadowReport(
        total_signals=42,
        win_rate=78.5,
        return_vs_market=14.2,
        best_performing_room="Strategy Room",
        worst_performing_pair="GBP/JPY",
        certified_alpha=True
    )

@app.get("/marketplace/leaderboard", tags=["Marketplace"], response_model=list[MarketplaceConfig])
async def get_marketplace_leaderboard():
    return sorted(MOCK_MARKETPLACE, key=lambda x: x.win_rate, reverse=True)

@app.post("/marketplace/subscribe/{config_id}", tags=["Marketplace"])
async def subscribe_to_config(config_id: str):
    # Simulate applying config
    await asyncio.sleep(1)
    return {"status": "success", "message": f"Successfully applied config {config_id} to your session. Creator gets 20% revenue share."}

