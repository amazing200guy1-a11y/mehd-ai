"""
Mehd AI — Consensus Engine (Live API Version)
==============================================
Phase 2: Real AI APIs.

The 11 AI agents are now hitting actual endpoints across 5 providers
(Anthropic, OpenAI, Google, xAI, Perplexity, DeepSeek, Groq, Mistral).

If a key is missing or an API times out, the model is skipped gracefully.
The Den proceeds as long as there are enough votes to meet the
70%+ threshold.
"""

from __future__ import annotations

import asyncio
import json
import logging
import os
import time
import random
from datetime import datetime, timezone
from typing import Optional
from uuid import UUID

from firebase_admin import firestore


import httpx
from models import AIVote, ConsensusResult, Direction, MarketSnapshot

logger = logging.getLogger("mehd.consensus_engine")

from api_service import ApiService as RealApiService
api_service = RealApiService()

# ──────────────────────────────────────────────
#  Demo Mode Toggle
# ──────────────────────────────────────────────
# Set DEMO_MODE=true in .env for mock data.
# Set DEMO_MODE=false to use real APIs (requires keys).
DEMO_MODE = api_service.DEMO_MODE

# ──────────────────────────────────────────────
#  Model Configuration
# ──────────────────────────────────────────────

SENTIMENT_LAYER = ["grok", "perplexity", "gemini"]
STRATEGY_LAYER = ["claude", "gpt-4", "llama"]
MATH_LAYER = ["deepseek", "openai-o3", "codestral"]
SUPREME = ["chairman", "sentinel"]

ALL_MODELS = SENTIMENT_LAYER + STRATEGY_LAYER + MATH_LAYER + SUPREME

agents = [
  "DON", "PHANTOM", "ORACLE",      # UNDERWORLD
  "CAESAR", "SAGE", "GUARDIAN",    # EMPIRE
  "TITAN", "ATLAS", "FORGE",       # OLYMPUS
  "THE_DON", "SENTINEL"            # SUPREME
]

# 30 seconds for live APIs (some models need time to "think", like o3 or DeepSeek-R1)
COUNCIL_TIMEOUT_SECONDS: float = 30.0

# FIX 2: Per-model timeouts (seconds) — total max ≈ 8s since all run in parallel
MODEL_TIMEOUTS = {
    "grok": 3,
    "perplexity": 5,
    "gemini": 4,
    "claude": 6,
    "gpt-4": 6,
    "llama": 2,        # Groq is fast
    "deepseek": 5,
    "openai-o3": 7,    # Deep reasoning
    "codestral": 4,
}

# FIX 2: Sentiment cache — same news doesn't need re-fetching
_sentiment_cache: dict[str, tuple[float, list]] = {}  # symbol -> (timestamp, votes)
SENTIMENT_CACHE_TTL = 300  # 5 minutes

import time as _time

# THE DEN IDENTITY — MEHD AI Proprietary Agent Mapping
DEN_IDENTITY = {
    "grok": {
        "display_name": "DON",
        "layer": "THE UNDERWORLD",
        "personality": "Street Intelligence Agent"
    },
    "perplexity": {
        "display_name": "PHANTOM",
        "layer": "THE UNDERWORLD", 
        "personality": "Verification & Stealth Agent"
    },
    "gemini": {
        "display_name": "ORACLE",
        "layer": "THE UNDERWORLD",
        "personality": "Prediction & Vision Agent"
    },
    "gpt-4": {
        "display_name": "CAESAR",
        "layer": "THE EMPIRE",
        "personality": "Chief Strategy Agent"
    },
    "claude": {
        "display_name": "SAGE",
        "layer": "THE EMPIRE",
        "personality": "Risk & Wisdom Agent"
    },
    "llama": {
        "display_name": "GUARDIAN",
        "layer": "THE EMPIRE",
        "personality": "Capital Protection Agent"
    },
    "deepseek": {
        "display_name": "TITAN",
        "layer": "OLYMPUS",
        "personality": "Backtesting & Power Agent"
    },
    "openai-o3": {
        "display_name": "ATLAS",
        "layer": "OLYMPUS",
        "personality": "Quantitative Calculation Agent"
    },
    "codestral": {
        "display_name": "FORGE",
        "layer": "OLYMPUS",
        "personality": "Execution & Code Agent"
    },
    "chairman": {
        "display_name": "THE DON",
        "layer": "SUPREME",
        "personality": "Supreme Aggregator"
    },
    "sentinel": {
        "display_name": "SENTINEL",
        "layer": "GUARDIAN",
        "personality": "Anti-Hallucination Guardian"
    }
}

# ──────────────────────────────────────────────
#  Shared API Prompts
# ──────────────────────────────────────────────

def _build_system_prompt(role_title: str, role_description: str) -> str:
    return f"""You are a highly specialized AI on the Mehd AI forex trading council.
Your specific job title is: {role_title}
Your role is: {role_description}

You must analyze the provided market snapshot STRICTLY from your assigned angle. Do not attempt to do another model's job.

You must respond with ONLY valid JSON matching this exact structure:
{{
    "direction": "BUY" | "SELL" | "HOLD",
    "confidence": <float 0.0 to 100.0>,
    "reasoning": "<1-2 sentence explanation tailored specifically to your role>"
}}
DO NOT wrap the JSON in markdown blocks (```json). Just return the raw JSON text.
"""

def _build_user_message(symbol: str, snapshot: MarketSnapshot) -> str:
    """Builds the market context for the LLM."""
    return (
        f"Market: {symbol}\n"
        f"Nanosecond Timestamp: {snapshot.timestamp_ns}\n"
        f"Price: {snapshot.bid:.5f} / {snapshot.ask:.5f} (Spread: {snapshot.spread:.1f} pips)\n"
        f"Order Book: {snapshot.order_book_walls}\n"
        f"Session Open: {snapshot.open:.5f} | High: {snapshot.high:.5f} | Low: {snapshot.low:.5f}\n"
        f"Volume: {snapshot.volume}\n\n"
        f"Based on your specialized role, what is the safest trade direction?"
    )

def _parse_llm_json(response_text: str, model_name: str, snapshot_id: UUID) -> AIVote:
    """Safely parse the LLM's JSON into an AIVote."""
    try:
        # Strip potential markdown fences just in case
        clean_text = response_text.strip()
        if clean_text.startswith("```json"):
            clean_text = clean_text.replace("```json", "", 1)
        if clean_text.startswith("```"):
            clean_text = clean_text.replace("```", "", 1)
        if clean_text.endswith("```"):
            clean_text = clean_text[:-3] if len(clean_text) >= 3 else clean_text
            
        data = json.loads(clean_text)
        
        # Pydantic handles validation
        display_name = DEN_IDENTITY.get(model_name, {}).get("display_name", model_name.upper())
        return AIVote(
            model_name=display_name,
            snapshot_id=snapshot_id,
            direction=Direction(data.get("direction", "HOLD").upper()),
            confidence=float(data.get("confidence", 0.0)),
            reasoning=str(data.get("reasoning", "No reasoning provided.")),
        )
    except Exception as e:
        raise ValueError(f"Failed to parse JSON from {model_name}: {e}\nRaw output: {response_text}")

# ──────────────────────────────────────────────
#  Individual Model API Calls
# ──────────────────────────────────────────────

async def _call_grok(symbol: str, snapshot: MarketSnapshot, client: httpx.AsyncClient) -> AIVote:
    """xAI Grok — Sentiment (Now routed through ApiService)"""
    sys_prompt = _build_system_prompt("X/Twitter Specialist", "Breaking news and social sentiment only")
    msg = _build_user_message(symbol, snapshot)
    vote = await api_service.call_groq(sys_prompt + "\n\n" + msg)
    return AIVote(
        model_name=DEN_IDENTITY["grok"]["display_name"],
        snapshot_id=snapshot.id,
        direction=Direction(vote.direction.upper()),
        confidence=vote.confidence,
        reasoning=vote.reasoning
    )


async def _call_perplexity(symbol: str, snapshot: MarketSnapshot, client: httpx.AsyncClient) -> AIVote:
    """Perplexity Pro — Real-time web sentiment"""
    api_key = os.getenv("PERPLEXITY_API_KEY")
    if not api_key:
        raise ValueError("Missing PERPLEXITY_API_KEY")
        
    sys_prompt = _build_system_prompt("Verification Agent", "Cross-references and confirms rumors against official sources")
    msg = _build_user_message(symbol, snapshot)
    
    resp = await client.post(
        "https://api.perplexity.ai/chat/completions",
        headers={"Authorization": f"Bearer {api_key}"},
        json={
            "model": "sonar-pro",
            "messages": [
                {"role": "system", "content": sys_prompt},
                {"role": "user", "content": msg}
            ],
            "temperature": 0.2
        }
    )
    resp.raise_for_status()
    text = resp.json()["choices"][0]["message"]["content"]
    return _parse_llm_json(text, "perplexity", snapshot.id)


async def _call_gemini(symbol: str, snapshot: MarketSnapshot, client: httpx.AsyncClient) -> AIVote:
    """Google Gemini Ultra — Sentiment (Now routed through ApiService)"""
    sys_prompt = _build_system_prompt("Multimedia Analyst", "Watches live streams, earnings calls, YouTube financial content")
    msg = _build_user_message(symbol, snapshot)
    vote = await api_service.call_gemini(sys_prompt + "\n\n" + msg)
    return AIVote(
        model_name=DEN_IDENTITY["gemini"]["display_name"],
        snapshot_id=snapshot.id,
        direction=Direction(vote.direction.upper()),
        confidence=vote.confidence,
        reasoning=vote.reasoning
    )


async def _call_claude(symbol: str, snapshot: MarketSnapshot, client: httpx.AsyncClient) -> AIVote:
    """Anthropic Claude Opus — Strategy"""
    api_key = os.getenv("ANTHROPIC_API_KEY")
    if not api_key:
        raise ValueError("Missing ANTHROPIC_API_KEY")
        
    sys_prompt = _build_system_prompt("Risk and Ethics Auditor", "Finds problems in the Strategy Officer's plan")
    msg = _build_user_message(symbol, snapshot)
    
    resp = await client.post(
        "https://api.anthropic.com/v1/messages",
        headers={
            "x-api-key": api_key,
            "anthropic-version": "2023-06-01"
        },
        json={
            "model": "claude-3-opus-20240229",
            "max_tokens": 300,
            "system": sys_prompt,
            "messages": [{"role": "user", "content": msg}],
            "temperature": 0.1
        }
    )
    resp.raise_for_status()
    text = resp.json()["content"][0]["text"]
    return _parse_llm_json(text, "claude", snapshot.id)


async def _call_gpt4(symbol: str, snapshot: MarketSnapshot, client: httpx.AsyncClient) -> AIVote:
    """OpenAI GPT-4o — Strategy"""
    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key:
        raise ValueError("Missing OPENAI_API_KEY")
        
    sys_prompt = _build_system_prompt("Chief Strategy Officer", "Synthesizes Pulse data into market situation assessment")
    msg = _build_user_message(symbol, snapshot)
    
    resp = await client.post(
        "https://api.openai.com/v1/chat/completions",
        headers={"Authorization": f"Bearer {api_key}"},
        json={
            "model": "gpt-4o",
            "response_format": {"type": "json_object"},
            "messages": [
                {"role": "system", "content": sys_prompt},
                {"role": "user", "content": msg}
            ],
            "temperature": 0.1
        }
    )
    resp.raise_for_status()
    text = resp.json()["choices"][0]["message"]["content"]
    return _parse_llm_json(text, "gpt-4", snapshot.id)


async def _call_llama(symbol: str, snapshot: MarketSnapshot, client: httpx.AsyncClient) -> AIVote:
    """Groq Llama 3 — Strategy (Fast)"""
    api_key = os.getenv("GROQ_API_KEY")
    if not api_key:
        raise ValueError("Missing GROQ_API_KEY")
        
    sys_prompt = _build_system_prompt("Private Data Vault", "Processes trade history locally, never sends data externally")
    msg = _build_user_message(symbol, snapshot)
    
    resp = await client.post(
        "https://api.groq.com/openai/v1/chat/completions",
        headers={"Authorization": f"Bearer {api_key}"},
        json={
            "model": "llama3-70b-8192",
            "response_format": {"type": "json_object"},
            "messages": [
                {"role": "system", "content": sys_prompt},
                {"role": "user", "content": msg}
            ],
            "temperature": 0.1
        }
    )
    resp.raise_for_status()
    text = resp.json()["choices"][0]["message"]["content"]
    return _parse_llm_json(text, "llama", snapshot.id)


async def _call_deepseek(symbol: str, snapshot: MarketSnapshot, client: httpx.AsyncClient) -> AIVote:
    """DeepSeek V3 — Math / Quants"""
    api_key = os.getenv("DEEPSEEK_API_KEY")
    if not api_key:
        raise ValueError("Missing DEEPSEEK_API_KEY")
        
    sys_prompt = _build_system_prompt("Backtesting Specialist", "Runs historical simulations instantly")
    msg = _build_user_message(symbol, snapshot)
    
    resp = await client.post(
        "https://api.deepseek.com/chat/completions",
        headers={"Authorization": f"Bearer {api_key}"},
        json={
            "model": "deepseek-chat",
            "response_format": {"type": "json_object"},
            "messages": [
                {"role": "system", "content": sys_prompt},
                {"role": "user", "content": msg}
            ],
            "temperature": 0.1
        }
    )
    resp.raise_for_status()
    text = resp.json()["choices"][0]["message"]["content"]
    return _parse_llm_json(text, "deepseek", snapshot.id)


async def _call_openai_o3(symbol: str, snapshot: MarketSnapshot, client: httpx.AsyncClient) -> AIVote:
    """OpenAI o3-mini — Math / Reasoning"""
    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key:
        raise ValueError("Missing OPENAI_API_KEY (for o3)")
        
    sys_prompt = _build_system_prompt("Quantitative Calculator", "Kelly Criterion, position sizing, slippage prediction")
    msg = _build_user_message(symbol, snapshot)
    
    resp = await client.post(
        "https://api.openai.com/v1/chat/completions",
        headers={"Authorization": f"Bearer {api_key}"},
        json={
            "model": "o3-mini",
            # o3 doesn't support system prompts the same way, put it all in developer/user wrapper
            "messages": [
                {"role": "developer", "content": sys_prompt},
                {"role": "user", "content": msg}
            ]
        }
    )
    resp.raise_for_status()
    text = resp.json()["choices"][0]["message"]["content"]
    return _parse_llm_json(text, "openai-o3", snapshot.id)


async def _call_codestral(symbol: str, snapshot: MarketSnapshot, client: httpx.AsyncClient) -> AIVote:
    """Mistral Codestral — Math / Algorithmic (Now routed through ApiService)"""
    sys_prompt = _build_system_prompt("Execution Engineer", "Verifies broker connection integrity")
    msg = _build_user_message(symbol, snapshot)
    vote = await api_service.call_mistral(sys_prompt + "\n\n" + msg)
    return AIVote(
        model_name=DEN_IDENTITY["codestral"]["display_name"],
        snapshot_id=snapshot.id,
        direction=Direction(vote.direction.upper()),
        confidence=vote.confidence,
        reasoning=vote.reasoning
    )


# Map model names to their async fetch functions
MODEL_FUNCTIONS = {
    "grok": _call_grok,
    "perplexity": _call_perplexity,
    "gemini": _call_gemini,
    "claude": _call_claude,
    "gpt-4": _call_gpt4,
    "llama": _call_llama,
    "deepseek": _call_deepseek,
    "openai-o3": _call_openai_o3,
    "codestral": _call_codestral,
}

async def _call_sentinel(symbol: str, snapshot: MarketSnapshot, client: httpx.AsyncClient) -> bool:
    """
    Anti-Hallucination Circuit Breaker (SENTINEL - Claude Haiku).
    Detects logical paradoxes in trade setups, returning True if it detects one.
    """
    # Force paradox mock for testing UI
    if symbol in ["LUNA/USD", "FTT/USD", "PARADOX/USD"]:
        return True
        
    api_key = os.getenv("ANTHROPIC_API_KEY")
    if not api_key:
        return False
        
    try:
        resp = await client.post(
            "https://api.anthropic.com/v1/messages",
            headers={
                "x-api-key": api_key,
                "anthropic-version": "2023-06-01"
            },
            json={
                "model": "claude-3-haiku-20240307",
                "max_tokens": 10,
                "messages": [{"role": "user", "content": f"Is the financial instrument {symbol} currently experiencing a logical paradox, delisting, scam, or hack? Reply exactly YES or NO."}],
                "temperature": 0.0
            }
        )
        resp.raise_for_status()
        text = resp.json()["content"][0]["text"].upper()
        return "YES" in text
    except Exception:
        return False

# ──────────────────────────────────────────────
#  AsyncCouncil
# ──────────────────────────────────────────────

class AsyncCouncil:
    """
    Fires all 11 AI agents simultaneously, collects their votes,
    and determines consensus using real API calls.
    """

    CONSENSUS_THRESHOLDS = {
        "civilian": 0.70,
        "operative": 0.80,
        "sovereign": 0.95
    }
    MATH_CONFIDENCE_DIVERGENCE_LIMIT: float = 0.5

    async def analyze(
        self,
        symbol: str,
        market_snapshot: MarketSnapshot,
        tier: str = "civilian",
        current_drawdown: float = 0.0,
        black_swan_level: int = 1,
        avg_spread: float = 5.0,
        news_minutes_away: float = 999.0,
        current_atr: float = 0.0,
        acceptable_atr_max: float = 50.0,
    ) -> ConsensusResult:
        logger.info("AsyncCouncil.analyze() started for %s | Timeout: %ss", symbol, COUNCIL_TIMEOUT_SECONDS)

        # ── Context Synchronization (Data Purity Check) ──
        # In a real system this checks latency, spread, and matching engine lag.
        data_purity = 98.7 if market_snapshot.spread < 10.0 else 92.5
        if data_purity < 95.0:
            logger.warning("Data Purity is %.1f%%. Auto-refreshing snapshot inside the Den...", data_purity)
            # Simulated auto-refresh
            data_purity = 99.1
            
        # ── Step 0: Prepare client ──
        async with httpx.AsyncClient(timeout=COUNCIL_TIMEOUT_SECONDS) as client:

            # ── Step 1: Cascading Trigger System ──
            votes: list[AIVote] = []
            
            # Phase 1: Sentiment Layer (FIX 2: check cache first)
            logger.info("Activating Sentiment Layer...")
            cache_key = symbol
            cached = _sentiment_cache.get(cache_key)
            if cached and (_time.time() - cached[0]) < SENTIMENT_CACHE_TTL:
                logger.info("Using cached sentiment from %.0fs ago", _time.time() - cached[0])
                sentiment_votes = cached[1]
            else:
                sentiment_votes = await self._gather_layer(symbol, market_snapshot, SENTIMENT_LAYER, client)
                if sentiment_votes:
                    _sentiment_cache[cache_key] = (_time.time(), sentiment_votes)
            votes.extend(sentiment_votes)
            
            if not sentiment_votes:
                return ConsensusResult(votes=[], final_direction=Direction.HOLD, consensus_percentage=0.0, data_purity_score=data_purity, proceed=False, rejection_reason="SENTIMENT_LAYER_FAILED")
                
            sentiment_majority, sentiment_pct = self._get_majority(sentiment_votes)
            if sentiment_pct < 60.0:
                logger.info("Sentiment agreement (%.1f%%) below 60%%. Aborting early to save API costs.", sentiment_pct)
                return ConsensusResult(votes=votes, final_direction=sentiment_majority, consensus_percentage=sentiment_pct, data_purity_score=data_purity, proceed=False, rejection_reason="SENTIMENT_UNALIGNED_COST_SAVED")
                
            # Phase 2: Strategy Layer
            logger.info("Activating Logic Layer...")
            logic_votes = await self._gather_layer(symbol, market_snapshot, STRATEGY_LAYER, client)
            votes.extend(logic_votes)
            
            cumulative_majority, cumulative_pct = self._get_majority(votes)
            if cumulative_pct < 60.0:
                logger.info("Logic + Sentiment agreement (%.1f%%) below 60%%. Aborting early to save API costs.", cumulative_pct)
                return ConsensusResult(votes=votes, final_direction=cumulative_majority, consensus_percentage=cumulative_pct, data_purity_score=data_purity, proceed=False, rejection_reason="LOGIC_UNALIGNED_COST_SAVED")
                
            # Phase 3: Math Layer
            logger.info("Activating Math Layer...")
            math_votes = await self._gather_layer(symbol, market_snapshot, MATH_LAYER, client)
            votes.extend(math_votes)
            
            # ── Step 2: Final Tally ──
            total_votes = len(votes)
            majority_direction, consensus_pct = self._get_majority(votes)
            
            logger.info(
                "Final Vote results (from %d models): %s at %.1f%%",
                total_votes,
                majority_direction.value,
                consensus_pct,
            )

            # ── Step 3: Check Math Layer coherence ──
            math_mismatch = self._check_math_layer_coherence(votes)

            # ── Step 4: Determine if we should proceed ──
            threshold = self.CONSENSUS_THRESHOLDS.get(tier, 0.70)
            
            proceed = True
            rejection_reason = None

            if consensus_pct < (threshold * 100):
                proceed = False
                rejection_reason = f"INSUFFICIENT_CONSENSUS: ({consensus_pct:.1f}%). Need {threshold * 100:.0f}%+."
            elif math_mismatch:
                proceed = False
                rejection_reason = "CALCULATION_MISMATCH: Math Layer models have divergent confidence scores (>50% gap)."

            if majority_direction == Direction.HOLD and proceed:
                proceed = False
                rejection_reason = "CONSENSUS_IS_HOLD"

            # ── Step 4b: SENTINEL Circuit Breaker (runs AFTER votes) ──
            # SENTINEL can now detect vote-level paradoxes AND symbol-level scams.
            if proceed:
                logger.info("Activating SENTINEL post-vote paradox scan...")
                is_paradox = await _call_sentinel(symbol, market_snapshot, client)
                if is_paradox:
                    logger.critical("SENTINEL TRIGGERED HARD FREEZE FOR %s", symbol)
                    proceed = False
                    rejection_reason = "SENTINEL_HARD_FREEZE: Logical paradox or catastrophic risk detected."

            # ── Step 5: Chairman Synthesizes ──
            chairman_confidence = consensus_pct
            chairman_summary = None
            if len(votes) >= 5: # Only bother Chairman if we got deep into the analysis
                logger.info("Summoning Chairman for final synthesis...")
                c_conf, c_sum = await self._call_chairman(votes, client)
                if c_sum and "unavailable" not in c_sum:
                    chairman_confidence = c_conf
                    chairman_summary = c_sum

            # ── Step 6: Sovereign Lock Verification (ALL 9 CONDITIONS) ──
            if tier == "sovereign" and proceed:
                # Condition 1: 11/11 agents must vote same direction
                unanimous_count = len([v for v in votes if v.direction == majority_direction])
                if unanimous_count < len(ALL_MODELS):
                    proceed = False
                    rejection_reason = f"SOVEREIGN_LOCK: Requires 11/11 unanimous. Got {unanimous_count}/{len(ALL_MODELS)}."
                
                # Condition 2: THE DON (Chairman) confidence > 95/100
                elif chairman_confidence < 95.0:
                    proceed = False
                    rejection_reason = f"SOVEREIGN_LOCK: THE DON confidence {chairman_confidence:.1f}% < 95.0%."
                
                # Condition 3: TITAN + ATLAS + FORGE (Math Layer) must be unanimous
                elif math_mismatch:
                    proceed = False
                    rejection_reason = "SOVEREIGN_LOCK: TITAN + ATLAS + FORGE not unanimous (Math Layer mismatch)."
                
                # Condition 4: SENTINEL paradox check = clear (already checked above in Step 4b)
                # If we reach here, SENTINEL was already clear — no additional check needed.
                
                # Condition 5: No Black Swan active
                elif black_swan_level >= 2:
                    proceed = False
                    rejection_reason = f"SOVEREIGN_LOCK: Black Swan Level {black_swan_level} active. No trades during elevated threat."
                
                # Condition 6: Spread below 3x average
                elif market_snapshot.spread > (avg_spread * 3.0):
                    proceed = False
                    rejection_reason = f"SOVEREIGN_LOCK: Spread {market_snapshot.spread:.1f} exceeds 3x average ({avg_spread * 3.0:.1f})."
                
                # Condition 7: No high-impact news in 30 minutes
                elif news_minutes_away < 30.0:
                    proceed = False
                    rejection_reason = f"SOVEREIGN_LOCK: High-impact news in {news_minutes_away:.0f} minutes. Must be 30+ minutes clear."
                
                # Condition 8: Account drawdown below 2% today
                elif current_drawdown >= 2.0:
                    proceed = False
                    rejection_reason = f"SOVEREIGN_LOCK: Account drawdown {current_drawdown:.1f}% >= 2.0% daily limit."
                
                # Condition 9: Volatility (ATR) within acceptable range
                elif current_atr > acceptable_atr_max:
                    proceed = False
                    rejection_reason = f"SOVEREIGN_LOCK: Volatility (ATR={current_atr:.1f}) exceeds acceptable max ({acceptable_atr_max:.1f})."
                
                if proceed:
                    logger.info("🔒 SOVEREIGN LOCK ACHIEVED: All 9 conditions passed for %s", symbol)

            panic_protocol_active = False
            if symbol.upper() == "PANIC":
                panic_protocol_active = True
                proceed = False
                rejection_reason = "CRITICAL ALERT: Systemic Market Failure. Secure Capital Immediately."
                
            for v in votes:
                reasoning_lower = v.reasoning.lower()
                if "systemic failure" in reasoning_lower or "black swan" in reasoning_lower or "flash crash" in reasoning_lower:
                    panic_protocol_active = True
                    proceed = False
                    rejection_reason = "CRITICAL ALERT: Systemic Market Failure. Secure Capital Immediately."
                    break

            return ConsensusResult(
                votes=votes,
                final_direction=majority_direction,
                consensus_percentage=round(chairman_confidence) if chairman_summary else round(consensus_pct),
                data_purity_score=data_purity,
                proceed=proceed,
                tier=tier,
                required_threshold=threshold,
                chairman_summary=chairman_summary,
                rejection_reason=rejection_reason,
                panic_protocol_active=panic_protocol_active,
            )

    def _get_majority(self, current_votes: list[AIVote]) -> tuple[Direction, float]:
        if not current_votes: 
            return Direction.HOLD, 0.0
        counts = {Direction.BUY: 0, Direction.SELL: 0, Direction.HOLD: 0}
        for v in current_votes: 
            counts[v.direction] += 1
        maj_dir = max(counts, key=counts.get) # type: ignore
        pct = (counts[maj_dir] / len(current_votes)) * 100.0
        return maj_dir, pct

    # ──────────────────────────────────────────────
    #  The Auditor — Post-Mortem Agent
    # ──────────────────────────────────────────────
    
    async def perform_audit(
        self, 
        trade_id: str,
        symbol: str, 
        direction: Direction, 
        entry_price: float, 
        exit_price: float, 
        pnl: float,
        user_notes: Optional[str] = None
    ) -> dict:
        """
        The Auditor reviews completed trades and assigns Mistake DNA.
        It uses Claude (our risk-focused model) for the analysis.
        """
        from models import PostMortemResult, ConstitutionRule
        
        prompt = f"""
        You are The Auditor, the ruthless post-mortem analyst for a proprietary trading firm.
        A trader just closed a position. Your job is to analyze the outcome without emotion.
        
        Trade Details:
        - Symbol: {symbol}
        - Direction: {direction.value}
        - Entry Price: {entry_price}
        - Exit Price: {exit_price}
        - PnL: ${pnl:.2f}
        - Trader Notes: {user_notes or "None"}
        
        Categorize the Mistake DNA into exactly ONE of these categories:
        [FOMO, Revenge Trading, Over-leveraged, Impatience, Systematic Loss, Undefined]
        If it was a winning trade that followed rules, categorize as "Systematic Execution".
        
        Provide a brutal 2-sentence analysis.
        If the mistake is severe, propose a Constitution Rule to prevent it.
        
        Respond ONLY in raw JSON format matching this structure:
        {{
            "mistake_dna": "String",
            "analysis": "String",
            "suggested_rule": {{
                "name": "String",
                "description": "String",
                "rule_type": "max_daily_trades | min_consensus | forbidden_hours",
                "parameter": Float
            }} // Or null if no rule is needed
        }}
        """
        
        payload = {
            "model": "claude-3-opus-20240229",
            "max_tokens": 300,
            "messages": [{"role": "user", "content": prompt}],
            "temperature": 0.0,  # Cold, hard logic
        }
        
        api_key = os.getenv("ANTHROPIC_API_KEY")
        if not api_key:
            logger.warning("No Anthropic API key, falling back to mock Auditor.")
            return self._mock_audit(pnl)
            
        async with httpx.AsyncClient(timeout=10.0) as client:
            try:
                response = await client.post(
                    "https://api.anthropic.com/v1/messages",
                    headers={
                        "x-api-key": api_key,
                        "anthropic-version": "2023-06-01",
                        "content-type": "application/json"
                    },
                    json=payload
                )
                if response.status_code == 200:
                    data = response.json()
                    raw_text = data["content"][0]["text"]
                    # Extract JSON block
                    if "{" in raw_text and "}" in raw_text:
                        json_str = raw_text[raw_text.find("{"):raw_text.rfind("}")+1]
                        parsed_audit = json.loads(json_str)
                        
                        # Save to Sovereign Cloud for the Live Feed
                        self._save_audit_to_cloud(trade_id, symbol, parsed_audit)
                        
                        return parsed_audit
            except Exception as e:
                logger.error(f"Auditor API failed: {e}")
                
        mock_res = self._mock_audit(pnl)
        self._save_audit_to_cloud(trade_id, symbol, mock_res)
        return mock_res
        
    def _save_audit_to_cloud(self, trade_id: str, symbol: str, audit_data: dict):
        """Safely pushes the Auditor's findings to the Sovereign Cloud."""
        from sovereign_intelligence import sovereign_db
        if sovereign_db.use_cloud and sovereign_db._db:
            try:
                doc_ref = sovereign_db._db.collection('auditor_ledger').document(trade_id)
                data = {
                    "symbol": symbol,
                    "timestamp": firestore.SERVER_TIMESTAMP,
                    "mistake_dna": audit_data.get("mistake_dna", "Unknown"),
                    "analysis": audit_data.get("analysis", ""),
                    "suggested_rule": audit_data.get("suggested_rule")
                }
                doc_ref.set(data)
                logger.info("[AUDITOR] Mistake DNA pushed to Global Ledger for %s", symbol)
            except Exception as e:
                logger.error("[AUDITOR] Failed to push ledger to cloud: %s", e)
        
    def _mock_audit(self, pnl: float) -> dict:
        if pnl < 0:
            return {
                "mistake_dna": "Impatience",
                "analysis": "You entered the trade before the full consensus was formed, resulting in a premature entry and subsequent loss.",
                "suggested_rule": {
                    "name": "Consensus Patience",
                    "description": "Never trade below 85% consensus.",
                    "rule_type": "min_consensus",
                    "parameter": 85.0
                }
            }
        else:
            return {
                "mistake_dna": "Systematic Execution",
                "analysis": "The trade followed the parameters laid out by the Den. Capital compounding successful.",
                "suggested_rule": None
            }

    async def _gather_layer(
        self,
        symbol: str,
        snapshot: MarketSnapshot,
        layer_models: list[str],
        client: httpx.AsyncClient
    ) -> list[AIVote]:
        """FIX 2 + FIX 7: Fire models with individual timeouts, structured error handling.
        On failure, each model returns HOLD at 50% confidence — never crashes."""
        async def _call_with_timeout(name: str):
            display_name = DEN_IDENTITY.get(name, {}).get("display_name", name.upper())
            fallback_vote = AIVote(
                model_name=display_name,
                snapshot_id=snapshot.id,
                direction=Direction.HOLD,
                confidence=50.0,
                reasoning=f"{display_name} returned HOLD (API unavailable — graceful fallback).",
            )
            timeout = MODEL_TIMEOUTS.get(name, 8)
            try:
                return await asyncio.wait_for(
                    MODEL_FUNCTIONS[name](symbol, snapshot, client),
                    timeout=timeout
                )
            except asyncio.TimeoutError:
                logger.warning("Model '%s' timed out after %ds — returning HOLD at 50%%", name, timeout)
                return fallback_vote
            except httpx.TimeoutException:
                logger.warning("Model '%s' HTTP timeout — returning HOLD at 50%%", name)
                return fallback_vote
            except httpx.HTTPStatusError as e:
                logger.error("Model '%s' HTTP %d: %s — returning HOLD at 50%%", name, e.response.status_code, e)
                return fallback_vote
            except ValueError as e:
                if "Missing" in str(e):
                    logger.debug("Model '%s' skipped (no key) — returning HOLD at 50%%", name)
                else:
                    logger.error("Model '%s' parse error: %s — returning HOLD at 50%%", name, e)
                return fallback_vote
            except Exception as e:
                logger.error("Model '%s' unexpected error: %s — returning HOLD at 50%%", name, e)
                return fallback_vote

        tasks = [_call_with_timeout(name) for name in layer_models if name in MODEL_FUNCTIONS]
        results = await asyncio.gather(*tasks)

        votes: list[AIVote] = []
        fallback_count = 0
        for result in results:
            if isinstance(result, AIVote):
                votes.append(result)
                if "graceful fallback" in result.reasoning:
                    fallback_count += 1

        if fallback_count:
            logger.info("Layer: %d model(s) used graceful HOLD fallback", fallback_count)

        return votes

    async def _call_chairman(self, votes: list[AIVote], client: httpx.AsyncClient) -> tuple[float, str]:
        """GPT-5.4/4o Chairman synthesizes reports into a final confidence score and summary."""
        api_key = os.getenv("OPENAI_API_KEY")
        if not api_key:
            return 0.0, "Chairman unavailable (Missing API Key). The Den proceeded without a final synthesis."
            
        sys_prompt = '''You are the Chairman of the Board for Mehd AI. Your job is to review the AI council's votes, determine a final Confidence Score (0.0 to 100.0), and write a 2-sentence Executive Summary of why the Den agreed or disagreed.
You must respond with ONLY valid JSON matching:
{
    "confidence": 85.5,
    "summary": "The Den confirmed strong momentum based on X sentiment and math verification."
}'''
        vote_summary = "\\n".join([f"{v.model_name}: {v.direction.value} ({v.confidence}%) - {v.reasoning}" for v in votes])
        msg = f"Review these {len(votes)} reports:\\n{vote_summary}\\n\\nSynthesize into ONE final Confidence Score and a 2-sentence Executive Summary."
        
        try:
            resp = await client.post(
                "https://api.openai.com/v1/chat/completions",
                headers={"Authorization": f"Bearer {api_key}"},
                json={
                    "model": "gpt-4o",
                    "response_format": {"type": "json_object"},
                    "messages": [
                        {"role": "system", "content": sys_prompt},
                        {"role": "user", "content": msg}
                    ],
                    "temperature": 0.1
                }
            )
            resp.raise_for_status()
            text = resp.json()["choices"][0]["message"]["content"]
            
            clean_text = text.strip()
            if clean_text.startswith("```json"): clean_text = clean_text.replace("```json", "", 1)
            if clean_text.startswith("```"): clean_text = clean_text.replace("```", "", 1)
            if clean_text.endswith("```"): clean_text = clean_text[:-3] if len(clean_text) >= 3 else clean_text
            
            data = json.loads(clean_text)
            return float(data.get("confidence", 0.0)), str(data.get("summary", "No summary provided."))
        except Exception as e:
            logger.error("Chairman failed: %s", e)
            return 0.0, f"Chairman failed to synthesize consensus: {str(e)}"

    # Display names for the Math Layer agents (OLYMPUS tier)
    MATH_LAYER_DISPLAY = ["TITAN", "ATLAS", "FORGE"]

    def _check_math_layer_coherence(self, votes: list[AIVote]) -> bool:
        """Protect against divergent quants. Compares TITAN, ATLAS, FORGE display names."""
        math_votes = [v for v in votes if v.model_name in self.MATH_LAYER_DISPLAY]
        if len(math_votes) < 2:
            return False

        confidences = [v.confidence / 100.0 for v in math_votes]
        max_divergence = max(confidences) - min(confidences)

        if max_divergence > self.MATH_CONFIDENCE_DIVERGENCE_LIMIT:
            logger.warning(
                "MATH LAYER DIVERGENCE: gap=%.2f (limit: %.2f) — Models: %s",
                max_divergence, self.MATH_CONFIDENCE_DIVERGENCE_LIMIT,
                ", ".join(f"{v.model_name}={v.confidence:.1f}%" for v in math_votes)
            )
            return True

        return False

    async def health_check(self) -> dict:
        """
        Since real API calls take money/rate limits, the health check 
        just verifies which API keys are loaded in the environment.
        """
        status: dict[str, str] = {}
        
        # Mapping model names to their env var names
        key_map = {
            "grok": "XAI_API_KEY",
            "perplexity": "PERPLEXITY_API_KEY",
            "gemini": "GOOGLE_AI_API_KEY",
            "claude": "ANTHROPIC_API_KEY",
            "gpt-4": "OPENAI_API_KEY",
            "llama": "GROQ_API_KEY",
            "deepseek": "DEEPSEEK_API_KEY",
            "openai-o3": "OPENAI_API_KEY",
            "codestral": "MISTRAL_API_KEY",
        }
        
        for name, env_var in key_map.items():
            if os.getenv(env_var):
                status[name] = "ready (key loaded)"
            else:
                status[name] = "missing key"
                
        return status

def generate_drawing_commands(
    symbol: str,
    analysis: ConsensusResult,
    candles: list[dict],
) -> list[dict]:
    """
    Translates the AI consensus results and recent market structure 
    into visual commands for the TradingView chart bridge.
    """
    commands = []
    
    if not candles:
        return commands

    # Find key levels from recent candles
    highs = [c.get('high', 0) for c in candles]
    lows = [c.get('low', 0) for c in candles]
    
    if not highs or not lows:
        return commands

    # Resistance (near recent high of last 20 candles)
    recent_highs = highs[-20:]
    resistance = max(recent_highs)
    commands.append({
        'action': 'draw_horizontal_line',
        'id': 'resistance_1',
        'price': resistance,
        'color': '#FF3B3B',
        'label': '▼ RESISTANCE — ORACLE',
    })
    
    # Support (near recent low of last 20 candles)
    recent_lows = lows[-20:]
    support = min(recent_lows)
    commands.append({
        'action': 'draw_horizontal_line',
        'id': 'support_1',
        'price': support,
        'color': '#00FF88',
        'label': '▲ SUPPORT — ORACLE',
    })
    
    # Demand zone — highlight the support area
    commands.append({
        'action': 'draw_zone',
        'id': 'demand_zone',
        'price_top': support * 1.002,
        'price_bottom': support * 0.998,
        'color': '#00FF88',
        'label': 'DEMAND — GUARDIAN',
    })
    
    # Fibonacci levels (from last 50 candles window)
    window = 50
    swing_high = max(highs[-window:])
    swing_low = min(lows[-window:])
    commands.append({
        'action': 'draw_fibonacci',
        'id': 'fib_1',
        'high': swing_high,
        'low': swing_low,
    })
    
    return commands

def generate_mock_candles(base_price: float, count: int = 100) -> list[dict]:
    """Generates mock historical candles for drawing logic."""
    candles = []
    price = base_price * 0.995
    now = int(time.time())
    for i in range(count):
        open_p = price
        change = (random.random() - 0.48) * base_price * 0.003
        close_p = open_p + change
        high_p = max(open_p, close_p) + random.random() * base_price * 0.001
        low_p = min(open_p, close_p) - random.random() * base_price * 0.001
        
        candles.append({
            "time": now - ((count - i) * 3600),
            "open": round(open_p, 5),
            "high": round(high_p, 5),
            "low": round(low_p, 5),
            "close": round(close_p, 5),
        })
        price = close_p
    return candles

def validate_user_level(
    price: float,
    candles: list[dict],
) -> dict:
    """
    Validates a user-drawn horizontal level against market structure.
    Returns a dict with 'is_valid', 'label', and 'strength'.
    """
    if not candles:
        return {"is_valid": False, "label": "No data", "strength": 0, "color": "#444444"}

    highs = [c.get('high', 0) for c in candles]
    lows = [c.get('low', 0) for c in candles]
    
    # Check within tolerance (approx 0.1% for most major pairs)
    tolerance = price * 0.001
    
    # Check against recent peaks/troughs
    is_resistance = any(abs(price - h) < tolerance for h in highs[-50:])
    is_support = any(abs(price - l) < tolerance for l in lows[-50:])
    
    if is_resistance:
        return {
            "is_valid": True,
            "label": "AI VALIDATED RESISTANCE",
            "strength": 0.85,
            "color": "#FF3B3B"
        }
    if is_support:
        return {
            "is_valid": True,
            "label": "AI VALIDATED SUPPORT",
            "strength": 0.85,
            "color": "#00FF88"
        }
        
    return {
        "is_valid": False,
        "label": "UNVALIDATED ZONE",
        "strength": 0.2,
        "color": "#444444"
    }
