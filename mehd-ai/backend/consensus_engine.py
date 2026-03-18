"""
Mehd AI — Consensus Engine (Live API Version)
==============================================
Phase 2: Real AI APIs.

The 9 AI models are now hitting actual endpoints across 5 providers
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
import logging
from datetime import datetime, timezone
from typing import Optional
from uuid import UUID

import httpx
from models import AIVote, ConsensusResult, Direction, MarketSnapshot

logger = logging.getLogger("mehd.consensus_engine")

# ──────────────────────────────────────────────
#  Model Configuration
# ──────────────────────────────────────────────

SENTIMENT_LAYER = ["grok", "perplexity", "gemini"]
STRATEGY_LAYER = ["claude", "gpt-4", "llama"]
MATH_LAYER = ["deepseek", "openai-o3", "codestral"]

ALL_MODELS = SENTIMENT_LAYER + STRATEGY_LAYER + MATH_LAYER

# 30 seconds for live APIs (some models need time to "think", like o3 or DeepSeek-R1)
COUNCIL_TIMEOUT_SECONDS: float = 30.0

# ──────────────────────────────────────────────
#  Shared API Prompts
# ──────────────────────────────────────────────

SYSTEM_PROMPT = """You are a highly specialized AI on the Mehd AI forex trading council. 
Your sole purpose is to analyze the provided market snapshot and vote on a direction.

You must respond with ONLY valid JSON matching this exact structure:
{
    "direction": "BUY" | "SELL" | "HOLD",
    "confidence": <float 0.0 to 100.0>,
    "reasoning": "<1-2 sentence explanation>"
}
DO NOT wrap the JSON in markdown blocks (```json). Just return the raw JSON text.
"""

def _build_user_message(symbol: str, snapshot: MarketSnapshot, angle: str) -> str:
    """Builds the market context for the LLM."""
    return (
        f"Market: {symbol}\n"
        f"Price: {snapshot.bid:.5f} / {snapshot.ask:.5f} (Spread: {snapshot.spread:.1f} pips)\n"
        f"Session Open: {snapshot.open:.5f} | High: {snapshot.high:.5f} | Low: {snapshot.low:.5f}\n"
        f"Volume: {snapshot.volume}\n\n"
        f"Analyze this purely from a {angle} perspective. What is the safest trade direction?"
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
        return AIVote(
            model_name=model_name,
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
    """xAI Grok — Sentiment"""
    api_key = os.getenv("XAI_API_KEY")
    if not api_key:
        raise ValueError("Missing XAI_API_KEY")
        
    msg = _build_user_message(symbol, snapshot, "social sentiment and macro news")
    
    resp = await client.post(
        "https://api.x.ai/v1/chat/completions",
        headers={"Authorization": f"Bearer {api_key}"},
        json={
            "model": "grok-beta",
            "messages": [
                {"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user", "content": msg}
            ],
            "temperature": 0.2
        }
    )
    resp.raise_for_status()
    text = resp.json()["choices"][0]["message"]["content"]
    return _parse_llm_json(text, "grok", snapshot.id)


async def _call_perplexity(symbol: str, snapshot: MarketSnapshot, client: httpx.AsyncClient) -> AIVote:
    """Perplexity Pro — Real-time web sentiment"""
    api_key = os.getenv("PERPLEXITY_API_KEY")
    if not api_key:
        raise ValueError("Missing PERPLEXITY_API_KEY")
        
    msg = _build_user_message(symbol, snapshot, "current web news aggregation and live sentiment")
    
    resp = await client.post(
        "https://api.perplexity.ai/chat/completions",
        headers={"Authorization": f"Bearer {api_key}"},
        json={
            "model": "sonar-pro",
            "messages": [
                {"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user", "content": msg}
            ],
            "temperature": 0.2
        }
    )
    resp.raise_for_status()
    text = resp.json()["choices"][0]["message"]["content"]
    return _parse_llm_json(text, "perplexity", snapshot.id)


async def _call_gemini(symbol: str, snapshot: MarketSnapshot, client: httpx.AsyncClient) -> AIVote:
    """Google Gemini Ultra — Sentiment"""
    api_key = os.getenv("GOOGLE_AI_API_KEY")
    if not api_key:
        raise ValueError("Missing GOOGLE_AI_API_KEY")
        
    msg = _build_user_message(symbol, snapshot, "broad global economic sentiment")
    
    resp = await client.post(
        f"https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key={api_key}",
        json={
            "contents": [{"parts": [{"text": SYSTEM_PROMPT + "\n\n" + msg}]}],
            "generationConfig": {"temperature": 0.2}
        }
    )
    resp.raise_for_status()
    data = resp.json()
    text = data["candidates"][0]["content"]["parts"][0]["text"]
    return _parse_llm_json(text, "gemini", snapshot.id)


async def _call_claude(symbol: str, snapshot: MarketSnapshot, client: httpx.AsyncClient) -> AIVote:
    """Anthropic Claude Opus — Strategy"""
    api_key = os.getenv("ANTHROPIC_API_KEY")
    if not api_key:
        raise ValueError("Missing ANTHROPIC_API_KEY")
        
    msg = _build_user_message(symbol, snapshot, "price action strategy, support/resistance, and chart patterns")
    
    resp = await client.post(
        "https://api.anthropic.com/v1/messages",
        headers={
            "x-api-key": api_key,
            "anthropic-version": "2023-06-01"
        },
        json={
            "model": "claude-3-opus-20240229",
            "max_tokens": 300,
            "system": SYSTEM_PROMPT,
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
        
    msg = _build_user_message(symbol, snapshot, "technical index strategy and candlestick analysis")
    
    resp = await client.post(
        "https://api.openai.com/v1/chat/completions",
        headers={"Authorization": f"Bearer {api_key}"},
        json={
            "model": "gpt-4o",
            "response_format": {"type": "json_object"},
            "messages": [
                {"role": "system", "content": SYSTEM_PROMPT},
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
        
    msg = _build_user_message(symbol, snapshot, "momentum breakdown and breakout strategy")
    
    resp = await client.post(
        "https://api.groq.com/openai/v1/chat/completions",
        headers={"Authorization": f"Bearer {api_key}"},
        json={
            "model": "llama3-70b-8192",
            "response_format": {"type": "json_object"},
            "messages": [
                {"role": "system", "content": SYSTEM_PROMPT},
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
        
    msg = _build_user_message(symbol, snapshot, "quantitative probabilities, standard deviations, and Monte Carlo estimates")
    
    resp = await client.post(
        "https://api.deepseek.com/chat/completions",
        headers={"Authorization": f"Bearer {api_key}"},
        json={
            "model": "deepseek-chat",
            "response_format": {"type": "json_object"},
            "messages": [
                {"role": "system", "content": SYSTEM_PROMPT},
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
        
    msg = _build_user_message(symbol, snapshot, "rigorous mathematical verification, volatility formulas, and statistical anomalies")
    
    resp = await client.post(
        "https://api.openai.com/v1/chat/completions",
        headers={"Authorization": f"Bearer {api_key}"},
        json={
            "model": "o3-mini",
            # o3 doesn't support system prompts the same way, put it all in developer/user wrapper
            "messages": [
                {"role": "developer", "content": "You must output JSON only matching: {direction:str, confidence:float, reasoning:str}"},
                {"role": "user", "content": msg}
            ]
        }
    )
    resp.raise_for_status()
    text = resp.json()["choices"][0]["message"]["content"]
    return _parse_llm_json(text, "openai-o3", snapshot.id)


async def _call_codestral(symbol: str, snapshot: MarketSnapshot, client: httpx.AsyncClient) -> AIVote:
    """Mistral Codestral — Math / Algorithmic"""
    api_key = os.getenv("MISTRAL_API_KEY")
    if not api_key:
        raise ValueError("Missing MISTRAL_API_KEY")
        
    msg = _build_user_message(symbol, snapshot, "algorithmic crossovers, programmatic trading rule evaluation, and raw math")
    
    resp = await client.post(
        "https://api.mistral.ai/v1/chat/completions",
        headers={"Authorization": f"Bearer {api_key}"},
        json={
            "model": "codestral-latest",
            "response_format": {"type": "json_object"},
            "messages": [
                {"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user", "content": msg}
            ],
            "temperature": 0.1
        }
    )
    resp.raise_for_status()
    text = resp.json()["choices"][0]["message"]["content"]
    return _parse_llm_json(text, "codestral", snapshot.id)


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
    Fires all 9 AI models simultaneously, collects their votes,
    and determines consensus using real API calls.
    """

    CONSENSUS_THRESHOLD: float = 0.70  # Lowered to 70% to match spec exactly
    MATH_CONFIDENCE_DIVERGENCE_LIMIT: float = 0.5

    async def analyze(
        self,
        symbol: str,
        market_snapshot: MarketSnapshot,
    ) -> ConsensusResult:
        logger.info("AsyncCouncil.analyze() started for %s | Timeout: %ss", symbol, COUNCIL_TIMEOUT_SECONDS)

        # ── Step 0: Sentinel Circuit Breaker ──
        async with httpx.AsyncClient(timeout=COUNCIL_TIMEOUT_SECONDS) as client:
            is_paradox = await _call_sentinel(symbol, market_snapshot, client)
            if is_paradox:
                logger.critical("SENTINEL TRIGGERED HARD FREEZE FOR %s", symbol)
                return ConsensusResult(
                    votes=[],
                    final_direction=Direction.HOLD,
                    consensus_percentage=0.0,
                    proceed=False,
                    rejection_reason="SENTINEL_HARD_FREEZE: Logical paradox or catastrophic risk detected.",
                )

        # ── Step 1: Fire all 9 models simultaneously ──
        votes = await self._gather_votes(symbol, market_snapshot)

        if not votes:
            logger.error("All models failed (no API keys?) — returning HOLD")
            return ConsensusResult(
                votes=[],
                final_direction=Direction.HOLD,
                consensus_percentage=0.0,
                proceed=False,
                rejection_reason="ALL_MODELS_FAILED_OR_NO_API_KEYS",
            )

        # ── Step 2: Count votes by direction ──────────
        vote_counts: dict[Direction, int] = {
            Direction.BUY: 0,
            Direction.SELL: 0,
            Direction.HOLD: 0,
        }
        for vote in votes:
            vote_counts[vote.direction] += 1

        total_votes = len(votes)
        majority_direction = max(vote_counts, key=vote_counts.get)  # type: ignore[arg-type]
        majority_count = vote_counts[majority_direction]
        consensus_pct = (majority_count / total_votes) * 100

        logger.info(
            "Vote results (from %d models): BUY=%d, SELL=%d, HOLD=%d → %s at %.1f%%",
            total_votes,
            vote_counts[Direction.BUY],
            vote_counts[Direction.SELL],
            vote_counts[Direction.HOLD],
            majority_direction.value,
            consensus_pct,
        )

        # ── Step 3: Check Math Layer coherence ────────
        math_mismatch = self._check_math_layer_coherence(votes)

        # ── Step 4: Determine if we should proceed ────
        proceed = True
        rejection_reason: Optional[str] = None

        required_votes_pct = majority_count / total_votes
        if required_votes_pct < self.CONSENSUS_THRESHOLD:
            proceed = False
            rejection_reason = (
                f"INSUFFICIENT_CONSENSUS: Only {majority_count}/{total_votes} models "
                f"agreed ({consensus_pct:.1f}%). Need {self.CONSENSUS_THRESHOLD * 100:.0f}%+."
            )

        elif math_mismatch:
            proceed = False
            rejection_reason = (
                "CALCULATION_MISMATCH: Math Layer models have divergent confidence scores (>50% gap). "
                "The quantitative analysis is unreliable."
            )

        # If HOLD won, proceed is technically irrelevant but we shouldn't trade
        if majority_direction == Direction.HOLD and proceed:
            proceed = False
            rejection_reason = "CONSENSUS_IS_HOLD"

        result = ConsensusResult(
            votes=votes,
            final_direction=majority_direction,
            consensus_percentage=round(consensus_pct),
            proceed=proceed,
            rejection_reason=rejection_reason,
        )

        return result

    async def _gather_votes(
        self,
        symbol: str,
        snapshot: MarketSnapshot,
    ) -> list[AIVote]:
        """Fire all HTTPX requests concurrently."""
        tasks = []
        model_names = []
        
        # We share one httpx client per den run for connection pooling
        async with httpx.AsyncClient(timeout=COUNCIL_TIMEOUT_SECONDS) as client:
            for name, func in MODEL_FUNCTIONS.items():
                tasks.append(func(symbol, snapshot, client))
                model_names.append(name)

            votes: list[AIVote] = []
            failed_models: list[str] = []

            results = await asyncio.gather(*tasks, return_exceptions=True)

            for name, result in zip(model_names, results):
                if isinstance(result, Exception):
                    # We expect Missing API key errors, don't spam the logs with tracebacks for those
                    if "Missing" in str(result):
                        logger.debug("Skipped predator '%s': %s", name, result)
                    else:
                        logger.error("Predator '%s' failed to fetch: %s", name, result)
                    failed_models.append(name)
                elif isinstance(result, AIVote):
                    votes.append(result)

            if failed_models:
                logger.info("The Den proceeded without %d predators: %s", len(failed_models), ", ".join(failed_models))

            return votes

    def _check_math_layer_coherence(self, votes: list[AIVote]) -> bool:
        """Protect against divergent quants."""
        math_votes = [v for v in votes if v.model_name in MATH_LAYER]
        if len(math_votes) < 2:
            return False

        confidences = [v.confidence / 100.0 for v in math_votes]
        max_divergence = max(confidences) - min(confidences)

        if max_divergence > self.MATH_CONFIDENCE_DIVERGENCE_LIMIT:
            logger.warning(
                "MATH LAYER DIVERGENCE: gap=%.2f (limit: %.2f)",
                max_divergence, self.MATH_CONFIDENCE_DIVERGENCE_LIMIT
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
