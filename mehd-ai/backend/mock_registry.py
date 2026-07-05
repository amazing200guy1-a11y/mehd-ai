"""
Mehd AI — Mock Registry
=========================
HONEST INVENTORY of every mock/simulation in the system.

WHY THIS EXISTS:
When someone asks "is this real?", you should be able to point
to this file and say: "Here's exactly what's mock, what's needed
to make it real, and the priority for each."

STATUS KEY:
  MOCK     = Returns hardcoded/random data. No real logic.
  PARTIAL  = Has real logic but falls back to mock when keys are missing.
  REAL     = Fully functional with real APIs.

UPDATE THIS FILE every time you add or remove a mock.
Last updated: 2026-04-18 (post-surgery)
"""

MOCK_REGISTRY = [
    # ══════════════════════════════════════════
    #  AI AGENT LAYER (Consensus Engine)
    # ══════════════════════════════════════════
    {
        "id": "MOCK_001",
        "component": "Consensus Engine",
        "location": "consensus_engine.py:242 (_call_grok)",
        "status": "REAL",
        "what": "Groq API call via direct httpx. Errors if GROQ_API_KEY missing (no silent mock).",
        "to_make_real": "Set GROQ_API_KEY in .env. Code is ready.",
        "priority": "DONE (code-wise)",
    },
    {
        "id": "MOCK_002",
        "component": "Consensus Engine",
        "location": "consensus_engine.py:282 (_call_gemini)",
        "status": "REAL",
        "what": "Gemini API call via direct httpx. Errors if GEMINI_API_KEY missing.",
        "to_make_real": "Set GEMINI_API_KEY in .env. Code is ready.",
        "priority": "DONE (code-wise)",
    },
    {
        "id": "MOCK_003",
        "component": "Consensus Engine",
        "location": "consensus_engine.py:431 (_call_codestral)",
        "status": "REAL",
        "what": "Mistral API call via direct httpx. Errors if MISTRAL_API_KEY missing.",
        "to_make_real": "Set MISTRAL_API_KEY in .env. Code is ready.",
        "priority": "DONE (code-wise)",
    },
    {
        "id": "MOCK_004",
        "component": "Consensus Engine",
        "location": "consensus_engine.py:256-279 (_call_perplexity)",
        "status": "REAL",
        "what": "Perplexity API call. Errors if PERPLEXITY_API_KEY is missing (no mock fallback).",
        "to_make_real": "Already real — just needs the API key.",
        "priority": "DONE (code-wise)",
    },
    {
        "id": "MOCK_005",
        "component": "Consensus Engine",
        "location": "consensus_engine.py:296-321 (other direct API calls)",
        "status": "REAL",
        "what": "Claude, GPT-4, Llama, DeepSeek, o3 — all have real API call code.",
        "to_make_real": "Set corresponding API keys. Code is ready.",
        "priority": "DONE (code-wise)",
    },

    # ══════════════════════════════════════════
    #  MARKET DATA LAYER
    # ══════════════════════════════════════════
    {
        "id": "MOCK_006",
        "component": "Data Streamer",
        "location": "data_streamer.py:327 (_generate_realistic_mock_tick)",
        "status": "PARTIAL",
        "what": "Price feed. Falls back to random-walk mock if no OANDA/Polygon/TwelveData key.",
        "to_make_real": "Set OANDA_API_KEY + OANDA_ACCOUNT_ID (best), or POLYGON_API_KEY, or TWELVEDATA_API_KEY",
        "priority": "CRITICAL — everything downstream depends on real prices",
    },

    # ══════════════════════════════════════════
    #  DEN ROUTER (Q&A Layer)
    # ══════════════════════════════════════════
    {
        "id": "MOCK_007",
        "component": "Den Router",
        "location": "routes/den.py (DenRouter class)",
        "status": "PARTIAL",
        "what": "Den Q&A now calls Groq/Llama for real responses. Falls back to hardcoded strings when GROQ_API_KEY is missing.",
        "to_make_real": "Set GROQ_API_KEY in .env (free tier available at console.groq.com).",
        "priority": "DONE (code-wise) — just needs API key",
    },

    # ══════════════════════════════════════════
    #  RISK ENGINE
    # ══════════════════════════════════════════
    {
        "id": "MOCK_008",
        "component": "Risk Engine",
        "location": "risk_engine.py:121 (HardRiskKernel.__init__)",
        "status": "MOCK",
        "what": "Account balance starts at $10,000 hardcoded. No broker connection.",
        "to_make_real": "Connect to broker API (OANDA/MT5) to fetch real account balance and equity.",
        "priority": "CRITICAL for live trading. Not needed for paper trading demos.",
    },

    # ══════════════════════════════════════════
    #  FEATURES
    # ══════════════════════════════════════════
    {
        "id": "MOCK_009",
        "component": "Shadow Mode",
        "location": "routes/den.py (activate_shadow_mode)",
        "status": "REAL",
        "what": "Now pulls real data from broadcaster status and storage. Counts actual signals and trades.",
        "to_make_real": "Already real — data improves as the system runs.",
        "priority": "DONE",
    },
    {
        "id": "MOCK_011",
        "component": "Journey Tracker",
        "location": "routes/den.py (den_journey)",
        "status": "REAL",
        "what": "Now calculates from actual trade history stored via storage layer. Phase auto-progresses.",
        "to_make_real": "Already real — accuracy improves with more trades.",
        "priority": "DONE",
    },
    {
        "id": "MOCK_013",
        "component": "Trade Execution",
        "location": "routes/trading.py:51 (execute_trade)",
        "status": "MOCK",
        "what": "Sleeps 150-450ms to simulate broker latency. No actual broker order sent.",
        "to_make_real": "Register a real broker executor with risk_gateway.register_executor().",
        "priority": "CRITICAL for live trading",
    },
    {
        "id": "MOCK_014",
        "component": "Executive Brief",
        "location": "routes/trading.py (brief generation)",
        "status": "REAL",
        "what": "Brief generated from real vote data and stored via storage abstraction (persistent with Firestore).",
        "to_make_real": "Set STORAGE_BACKEND=firestore in .env for production persistence.",
        "priority": "DONE",
    },
]


def get_mock_summary() -> dict:
    """Returns a summary of mock vs real components."""
    total = len(MOCK_REGISTRY)
    mock_count = sum(1 for m in MOCK_REGISTRY if m["status"] == "MOCK")
    partial_count = sum(1 for m in MOCK_REGISTRY if m["status"] == "PARTIAL")
    real_count = sum(1 for m in MOCK_REGISTRY if m["status"] == "REAL")
    critical = [m for m in MOCK_REGISTRY if m.get("priority", "").startswith("CRITICAL")]

    return {
        "total_components": total,
        "fully_mock": mock_count,
        "partial_mock": partial_count,
        "fully_real": real_count,
        "reality_score": f"{((real_count + partial_count * 0.5) / total * 100):.0f}%",
        "critical_blockers": [
            {"id": c["id"], "what": c["what"]} for c in critical
        ],
    }
