"""
Mehd AI — Admin Routes
========================
Endpoints: /health, /health/detailed, /security/alerts,
           /audit-trail, /backtest

Operations, monitoring, and diagnostics.
"""

from __future__ import annotations

import asyncio
import logging
import os
from datetime import datetime, timezone
from typing import List

from fastapi import APIRouter, HTTPException, Request, Depends
from pydantic import BaseModel
from slowapi import Limiter

from anomaly_detector import anomaly_detector
from auth import get_current_user, get_current_user_mfa, get_sovereign_user, get_real_ip, get_uid_rate_key
from state import audit

logger = logging.getLogger("mehd.routes.admin")
router = APIRouter()
limiter = Limiter(key_func=get_uid_rate_key)


def _check_key(key_name: str) -> str:
    val = os.getenv(key_name)
    if val and len(val) > 10:
        return "active"
    return "missing key"


@router.get("/health")
async def health_check():
    """Public health check — returns aggregate system state for uptime monitors.
    HARDENED (VULN-07): Never leaks subsystem topology, queue depths, or retry counters."""
    from system_health import health_registry
    aggregate = await health_registry.aggregate_state()
    return {
        "status": aggregate,
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }


@router.get("/health/detailed", tags=["Admin"])
async def health_check_detailed(uid: str = Depends(get_sovereign_user)):
    """Detailed health check — requires authentication."""
    model_status = {
        "grok": _check_key("GROQ_API_KEY"),
        "perplexity": _check_key("PERPLEXITY_API_KEY"),
        "gemini": _check_key("GEMINI_API_KEY"),
        "claude": _check_key("ANTHROPIC_API_KEY"),
        "gpt-4": _check_key("OPENAI_API_KEY"),
        "llama": _check_key("GROQ_API_KEY"),
        "deepseek": _check_key("DEEPSEEK_API_KEY"),
        "openai-o3": _check_key("OPENAI_API_KEY"),
        "codestral": _check_key("MISTRAL_API_KEY"),
        "THE_DON_chairman": "active_always",
        "SENTINEL_guard": "active_always",
    }

    active_count = sum(1 for v in model_status.values() if v != "missing key")

    return {
        "status": "degraded" if active_count < 5 else "healthy",
        "total_agents": 11,
        "active_agents": active_count,
        "api_agents": 9,
        "logic_agents": 2,
        "risk_engine": "loaded",
        "model_status": model_status,
        "anomaly_monitor": anomaly_detector.get_status(),
        "note": "Add API keys to activate agents",
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }


@router.get("/ops/health", tags=["Admin"])
async def ops_health(uid: str = Depends(get_sovereign_user)):
    """Sovereign-only operational health dashboard.
    Returns full subsystem health with metrics for diagnostics.
    NEVER exposed to public clients."""
    from system_health import health_registry
    return await health_registry.snapshot(ops_level=True)


@router.get("/security/alerts", tags=["Admin"])
@limiter.limit("30/minute")
async def get_security_alerts(
    request: Request, limit: int = 50, uid: str = Depends(get_sovereign_user)
):
    safe_limit = min(max(limit, 1), 200)
    return {
        "alerts": anomaly_detector.get_recent_alerts(safe_limit),
        "status": anomaly_detector.get_status(),
    }


@router.get(
    "/audit-trail",
    response_model=List[dict],
    summary="Get recent trades and their risk decisions",
    tags=["Audit"],
)
@limiter.limit("30/minute")
async def get_audit_trail(
    request: Request, limit: int = 50, uid: str = Depends(get_sovereign_user)
):
    safe_limit = min(max(limit, 1), 200)
    try:
        logs = audit.get_recent_logs(limit=safe_limit)
        return logs
    except Exception as e:
        logger.error("Error fetching audit trail: %s", e)
        raise HTTPException(
            status_code=500, detail="Audit trail temporarily unavailable."
        )


# ──────────────────────────────────────────────
#  Backtesting
# ──────────────────────────────────────────────

class BacktestRequest(BaseModel):
    symbol: str = "EUR/USD"
    num_candles: int = 500
    timeframe_hours: int = 4
    risk_per_trade_pct: float = 1.0
    min_consensus_pct: float = 70.0


@router.post(
    "/backtest",
    summary="Run a historical backtest of the consensus engine",
    tags=["Backtesting"],
)
@limiter.limit("2/minute")
async def run_backtest(
    request: Request,
    config: BacktestRequest,
    uid: str = Depends(get_sovereign_user),
):
    from state import VALID_SYMBOLS

    if config.symbol not in VALID_SYMBOLS:
        raise HTTPException(status_code=400, detail="Invalid symbol for backtesting")
    
    # SECURITY (VULN-04): The Interrogation Room Defense
    # Even Sovereign users are hard-capped to 10 backtests per day.
    # This makes it mathematically impossible to scrape enough decision 
    # data to train a neural network clone of the 11-agent consensus engine.
    from storage import storage
    today = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    backtest_key = f"{uid}_{today}"
    success = await storage.check_and_increment("backtest_counts", backtest_key, "count", 10)
    
    if not success:
        logger.critical("REVERSE ENGINEERING BLOCK: User %s attempted to fuzz the backtest engine.", uid)
        raise HTTPException(
            status_code=429,
            detail="Daily backtest limit reached (10/10). This strict limit protects Mehd AI's proprietary models from reverse-engineering."
        )

    if not (50 <= config.num_candles <= 2000):
        raise HTTPException(
            status_code=400, detail="Candle count must be between 50 and 2000"
        )
    if config.timeframe_hours not in [1, 4, 24]:
        raise HTTPException(
            status_code=400, detail="Timeframe must be 1, 4, or 24 hours"
        )
    if not (0.1 <= config.risk_per_trade_pct <= 2.0):
        raise HTTPException(
            status_code=400,
            detail="Risk per trade must be between 0.1% and 2.0%",
        )

    from backtest_engine import BacktestEngine
    import concurrent.futures

    loop = asyncio.get_event_loop()

    def _run():
        engine = BacktestEngine(starting_balance=10_000.0)
        return engine.run(
            symbol=config.symbol,
            num_candles=config.num_candles,
            timeframe_hours=config.timeframe_hours,
            risk_per_trade_pct=config.risk_per_trade_pct,
            min_consensus_pct=config.min_consensus_pct,
        )

    with concurrent.futures.ThreadPoolExecutor() as pool:
        report = await loop.run_in_executor(pool, _run)

    return report.to_dict()

# ──────────────────────────────────────────────
#  Security & Incident Response
# ──────────────────────────────────────────────

# NOTE: The unauthenticated `/security/trigger-lockdown` endpoint was removed
# to patch a Denial of Service vulnerability (Sniper DoS).
# MFA Fatigue and failed login logic is now handled securely inside auth.py.


# ──────────────────────────────────────────────
#  Constitution Rule Management (Fix 4)
#  Admin-only endpoints to review, approve, and
#  reject sandboxed Post-Mortem rules before they
#  affect the live Risk Kernel.
# ──────────────────────────────────────────────

@router.get(
    "/constitution/pending",
    summary="List all pending constitution rules awaiting review",
    tags=["Constitution"],
)
@limiter.limit("30/minute")
async def list_pending_rules(request: Request, uid: str = Depends(get_sovereign_user)):
    """Returns all autonomous rules queued by the Post-Mortem agent for admin review."""
    from post_mortem_agent import post_mortem
    pending = await post_mortem.get_pending_rules()
    return {"pending_rules": pending, "count": len(pending)}


@router.post(
    "/constitution/approve/{rule_id}",
    summary="Approve a pending constitution rule and activate it in the live Risk Kernel",
    tags=["Constitution"],
)
@limiter.limit("30/minute")
async def approve_constitution_rule(
    request: Request, rule_id: str, uid: str = Depends(get_sovereign_user)
):
    """Promotes a sandboxed rule from the pending queue into the live app_constitution."""
    from post_mortem_agent import post_mortem
    approved = await post_mortem.approve_pending_rule(rule_id)
    if not approved:
        raise HTTPException(status_code=404, detail=f"Rule '{rule_id}' not found in pending queue.")
    logger.info("CONSTITUTION: Admin %s approved rule %s", uid, rule_id)
    return {"status": "approved", "rule": approved}


@router.delete(
    "/constitution/reject/{rule_id}",
    summary="Reject and permanently discard a pending constitution rule",
    tags=["Constitution"],
)
@limiter.limit("30/minute")
async def reject_constitution_rule(
    request: Request, rule_id: str, uid: str = Depends(get_sovereign_user)
):
    """Permanently discards a sandboxed rule without activating it."""
    from post_mortem_agent import post_mortem
    rejected = await post_mortem.reject_pending_rule(rule_id)
    if not rejected:
        raise HTTPException(status_code=404, detail=f"Rule '{rule_id}' not found in pending queue.")
    logger.info("CONSTITUTION: Admin %s rejected rule %s", uid, rule_id)
    return {"status": "rejected", "rule_id": rule_id}
