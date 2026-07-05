import logging
import os
import re as _re
import json
from uuid import UUID
from typing import Optional
from models import AIVote, Direction, MarketSnapshot

logger = logging.getLogger("mehd.consensus_helpers")

# ──────────────────────────────────────────────
#  Model Configuration
# ──────────────────────────────────────────────

SENTIMENT_LAYER = ["grok-beta", "sonar-small-online", "gemini-1.5-flash"]
STRATEGY_LAYER = ["claude-3-5-sonnet-20240620", "gpt-4o", "llama-3.1-70b"]
MATH_LAYER = ["deepseek-chat", "o3-mini", "codestral-latest"]
SUPREME = ["claude-3-haiku-20240307", "gpt-4o-mini"]

ALL_MODELS = SENTIMENT_LAYER + STRATEGY_LAYER + MATH_LAYER + SUPREME

agents = [
  "DON", "PHANTOM", "ORACLE",      # UNDERWORLD
  "CAESAR", "SAGE", "GUARDIAN",    # EMPIRE
  "TITAN", "ATLAS", "FORGE",       # OLYMPUS
  "THE_DON", "SENTINEL"            # SUPREME
]

# 30 seconds for live APIs (some models need time to "think", like o3 or DeepSeek-R1)
COUNCIL_TIMEOUT_SECONDS: float = 30.0

# Per-model timeouts (seconds) — total max ≈ 8s since all run in parallel
MODEL_TIMEOUTS = {
    # Layer 1
    "grok-beta": 3,
    "sonar-small-online": 5,
    "gemini-1.5-flash": 4,
    # Layer 2
    "claude-3-5-sonnet-20240620": 6,
    "gpt-4o": 6,
    "llama-3.1-70b": 2,        # Groq is fast
    # Layer 3
    "deepseek-chat": 5,
    "o3-mini": 7,    # Deep reasoning
    "codestral-latest": 4,
    # Layer 4 (Reviewers)
    "claude-3-haiku-20240307": 1,
    "gpt-4o-mini": 1,
}

# THE DEN IDENTITY — MEHD AI Proprietary Agent Mapping
DEN_IDENTITY = {
    "grok-beta": {
        "display_name": "DON",
        "layer": "THE UNDERWORLD",
        "personality": "Street Intelligence Agent"
    },
    "sonar-small-online": {
        "display_name": "PHANTOM",
        "layer": "THE UNDERWORLD", 
        "personality": "Verification & Stealth Agent"
    },
    "gemini-1.5-flash": {
        "display_name": "ORACLE",
        "layer": "THE UNDERWORLD",
        "personality": "Prediction & Vision Agent"
    },
    "gpt-4o": {
        "display_name": "CAESAR",
        "layer": "THE EMPIRE",
        "personality": "Chief Strategy Agent"
    },
    "claude-3-5-sonnet-20240620": {
        "display_name": "SAGE",
        "layer": "THE EMPIRE",
        "personality": "Risk & Wisdom Agent"
    },
    "llama-3.1-70b": {
        "display_name": "GUARDIAN",
        "layer": "THE EMPIRE",
        "personality": "Capital Protection Agent"
    },
    "deepseek-chat": {
        "display_name": "TITAN",
        "layer": "OLYMPUS",
        "personality": "Backtesting & Power Agent"
    },
    "o3-mini": {
        "display_name": "ATLAS",
        "layer": "OLYMPUS",
        "personality": "Quantitative Calculation Agent"
    },
    "codestral-latest": {
        "display_name": "FORGE",
        "layer": "OLYMPUS",
        "personality": "Execution & Code Agent"
    },
    "claude-3-haiku-20240307": {
        "display_name": "THE DON",
        "layer": "SUPREME",
        "personality": "Supreme Aggregator"
    },
    "gpt-4o-mini": {
        "display_name": "SENTINEL",
        "layer": "GUARDIAN",
        "personality": "Anti-Hallucination Guardian"
    }
}

# ──────────────────────────────────────────────
#  Security: LLM Output Sanitization
# ──────────────────────────────────────────────

def _sanitize_reasoning(text: str, max_length: int = 500) -> str:
    """Strips control characters and caps length to prevent prompt injection chains."""
    if not isinstance(text, str):
        return "No reasoning provided."
    clean = _re.sub(r'[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]', '', text)
    return clean[:max_length].strip() or "No reasoning provided."

def _sanitize_confidence(value: float) -> float:
    """Server-side clamp — never trust an LLM to stay in range."""
    try:
        clamped = float(value)
    except (ValueError, TypeError):
        return 50.0  # Default to uncertain on parse failure
    return max(0.0, min(100.0, clamped))

# ──────────────────────────────────────────────
#  Shared API Prompts (loaded from private vault)
# ──────────────────────────────────────────────

def _load_vault() -> tuple[str, dict]:
    """Load the master prompt template AND agent roles from the private vault."""
    fallback_template = (
        "You are an AI trading analyst. Your role: {role_title} — {role_description}\n"
        "Analyze the market data and respond with ONLY valid JSON:\n"
        '{{"direction": "BUY" | "SELL" | "HOLD", '
        '"confidence": <float 0.0 to 100.0>, '
        '"reasoning": "<1-2 sentence explanation>"}}\n'
        "Return ONLY the JSON object, no markdown."
    )
    try:
        import importlib.util
        # The prompt vault is located in the backend root directory (one level up from consensus/)
        vault_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), ".prompt_vault.py")
        if os.path.exists(vault_path):
            spec = importlib.util.spec_from_file_location("_prompt_vault", vault_path)
            vault = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(vault)
            logger.info("Prompt Vault loaded — proprietary prompts + agent roles active")
            return vault.CONSENSUS_MASTER_TEMPLATE, getattr(vault, "AGENT_ROLES", {})
    except Exception as e:
        logger.warning("Prompt Vault load failed (%s) — using generic fallback", e)
    
    logger.warning("Prompt Vault NOT FOUND — using generic fallback prompts")
    return fallback_template, {}

_VAULT_TEMPLATE, _VAULT_ROLES = _load_vault()

def _build_system_prompt(role_title: str, role_description: str) -> str:
    return _VAULT_TEMPLATE.format(role_title=role_title, role_description=role_description)

def _get_vault_role(vault_key: str, fallback_title: str, fallback_desc: str) -> tuple[str, str]:
    """Get the title and description from the vault, or use fallbacks."""
    role = _VAULT_ROLES.get(vault_key, {})
    return role.get("title", fallback_title), role.get("description", fallback_desc)

def _build_user_message(symbol: str, snapshot: MarketSnapshot) -> str:
    """Builds the market context for the LLM."""
    base_msg = (
        "<market_data>\n"
        f"Market: {symbol}\n"
        f"Nanosecond Timestamp: {snapshot.timestamp_ns}\n"
        f"Price: {snapshot.bid:.5f} / {snapshot.ask:.5f} (Spread: {snapshot.spread:.1f} pips)\n"
        f"Order Book: {snapshot.order_book_walls}\n"
        f"Session Open: {snapshot.open:.5f} | High: {snapshot.high:.5f} | Low: {snapshot.low:.5f}\n"
        f"Volume: {snapshot.volume}\n"
        "</market_data>\n\n"
    )
    
    if snapshot.briefing:
        base_msg += f"<secretary_briefing>\n{snapshot.briefing}\n</secretary_briefing>\n\n"
        
    base_msg += f"Based on your specialized role, what is the safest trade direction?"
    return base_msg

def _parse_llm_json(response_text: str, model_name: str, snapshot_id: UUID) -> AIVote:
    """Safely parse the LLM's JSON into an AIVote with security sanitization."""
    try:
        clean_text = response_text.strip()
        if clean_text.startswith("```json"):
            clean_text = clean_text.replace("```json", "", 1)
        if clean_text.startswith("```"):
            clean_text = clean_text.replace("```", "", 1)
        if clean_text.endswith("```"):
            clean_text = clean_text[:-3] if len(clean_text) >= 3 else clean_text
            
        data = json.loads(clean_text)
        
        raw_direction = str(data.get("direction", "HOLD")).upper().strip()
        if raw_direction not in ("BUY", "SELL", "HOLD"):
            raw_direction = "HOLD"
        
        confidence = _sanitize_confidence(data.get("confidence", 50.0))
        reasoning = _sanitize_reasoning(str(data.get("reasoning", "No reasoning provided.")))
        
        display_name = DEN_IDENTITY.get(model_name, {}).get("display_name", model_name.upper())
        return AIVote(
            model_name=display_name,
            snapshot_id=snapshot_id,
            direction=Direction(raw_direction),
            confidence=confidence,
            reasoning=reasoning,
        )
    except Exception as e:
        raise ValueError("Failed to parse JSON from %s: %s" % (model_name, e))
