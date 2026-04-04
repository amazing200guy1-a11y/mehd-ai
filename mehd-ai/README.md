# Mehd AI — Forex Trading Assistant

> Multi-model AI consensus engine with unbreakable risk rules.  
> Protects traders from losing money through 11-agent voting, hard-coded safety limits, and permanent audit logging.

---

## What Is This?

Mehd AI is a forex trading assistant that works like a **council of eleven AI experts**. Before any trade is allowed, eleven different AI agents analyze the market from three perspectives:

| Layer | Agents | What They Analyze |
|-------|--------|-------------------|
| **Sentiment** | Grok, Perplexity, Gemini | News tone, social media, fear/greed index |
| **Strategy** | Claude, GPT-4, Llama | Chart patterns, indicators, technical signals |
| **Math** | DeepSeek, OpenAI o3, Codestral | Probabilities, statistics, quantitative models |
| **Oversight** | The Don, Sentinel | Final veto, risk governance |

If **8 out of 11 agents agree** on a direction, the trade button unlocks. If they disagree, the system protects you by holding.

On top of that, a **Hard Risk Kernel** enforces strict safety rules that **no AI can override**:
- Maximum 1% of your balance at risk per trade
- Every trade must have a stop-loss
- If you lose 3% in one day, trading is locked for 24 hours
- If volatility is too high, the trade button is greyed out

Every decision is **permanently logged** to Firebase Firestore so you can always see exactly what happened and why.

---

## File Structure

```
mehd-ai/
├── backend/
│   ├── main.py              ← FastAPI app — the front door (4 endpoints)
│   ├── models.py            ← Pydantic v2 data models — strict data shapes
│   ├── risk_engine.py       ← HardRiskKernel — unbreakable safety rules
│   ├── consensus_engine.py  ← AsyncCouncil — 11 AI agents vote simultaneously
│   ├── audit_trail.py       ← AuditLogger — Firebase Firestore + fallback log
│   ├── requirements.txt     ← Pinned Python dependencies
│   ├── Procfile             ← Railway deployment config
│   ├── .env.example         ← Environment variable template
│   └── fallback_log.json    ← Auto-created if Firestore is unavailable
└── README.md                ← You are here
```

### How The Files Connect

```
Flutter App (later)
    │
    ▼
main.py (FastAPI)
    ├── GET /analyze/{symbol}  ──→  consensus_engine.py (11 agents vote)
    ├── POST /execute          ──→  risk_engine.py (safety check FIRST)
    │                               then audit_trail.py (log the decision)
    ├── GET /account_health    ──→  risk_engine.py (account status)
    └── GET /health            ──→  self-check all systems
    
All data flows through models.py (strict Pydantic shapes)
All decisions logged through audit_trail.py (Firebase Firestore)
```

---

## How To Run Locally

### Prerequisites
- Python 3.11 or newer
- pip

### Steps

1. **Clone and navigate to the backend:**
   ```bash
   cd mehd-ai/backend
   ```

2. **Create a virtual environment (recommended):**
   ```bash
   python -m venv venv
   # Windows:
   venv\Scripts\activate
   # macOS/Linux:
   source venv/bin/activate
   ```

3. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

4. **Set up environment variables:**
   ```bash
   copy .env.example .env
   ```
   Then edit `.env` with your Firebase credentials. If you don't have Firebase set up yet, the system will use the local fallback log.

5. **Start the server:**
   ```bash
   uvicorn main:app --reload --port 8000
   ```

6. **Test it:**
   - Health check: [http://localhost:8000/health](http://localhost:8000/health)
   - Analyze EUR/USD: [http://localhost:8000/analyze/EURUSD](http://localhost:8000/analyze/EURUSD)
   - Account status: [http://localhost:8000/account_health](http://localhost:8000/account_health)
   - Interactive API docs: [http://localhost:8000/docs](http://localhost:8000/docs)

---

## API Endpoints

| Method | Path | What It Does |
|--------|------|--------------|
| `GET` | `/analyze/{symbol}` | Fire 11 AI agents, return consensus result |
| `POST` | `/execute` | Submit trade order — risk kernel runs first |
| `GET` | `/account_health` | Current balance, drawdown, lock status |
| `GET` | `/health` | System heartbeat + agent status |

---

## Deployment (Railway)

1. Push the `backend/` folder to a Git repo
2. Connect the repo to [Railway](https://railway.app)
3. Set environment variables in Railway dashboard
4. Railway reads the `Procfile` and deploys automatically

---

## Phase Roadmap

| Phase | Status | What Happens |
|-------|--------|--------------|
| **Phase 1** | ✅ Complete | Backend structure, mock AI agents, working API |
| **Phase 2** | 🔜 Next | Connect real AI APIs (11 live agents) |
| **Phase 3** | ✅ Complete | Flutter frontend (IDE-style dark theme) |
| **Phase 4** | 📋 Planned | Live market data feed integration |
| **Phase 5** | 📋 Planned | Broker API connection for real trade execution |

---

## Tech Stack

- **Python 3.11+** — async-first, type-safe
- **FastAPI** — modern async web framework
- **Pydantic v2** — strict data validation
- **Firebase Firestore** — real-time audit logging
- **asyncio** — concurrent 11-agent execution
- **uvicorn** — ASGI server

---

*Built with the philosophy: "Protect the trader first, profit second."*
