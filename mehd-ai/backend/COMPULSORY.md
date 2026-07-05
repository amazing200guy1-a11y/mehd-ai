# MEHD AI — COMPULSORY SYSTEM CONSTITUTION

File Name: COMPULSORY.md

## PURPOSE

This file is the mandatory constitutional blueprint for ALL AI agents, developers, automation systems, contributors, and future modifications inside the Mehd AI ecosystem.

Before creating, modifying, refactoring, optimizing, deleting, or restructuring ANY file, EVERY AI must read and obey this document.

The purpose is to:

- prevent architectural drift
- stop accidental system breakage
- preserve institutional-grade risk logic
- maintain alignment with the philosophy:

"AI THINKS → CODE DECIDES & EXECUTES"

No feature, optimization, UI enhancement, or AI behavior may violate this constitution.

---

## CORE PHILOSOPHY

### RULE 1 — AI NEVER HAS EXECUTION AUTHORITY

AI is ONLY allowed to:

- analyze
- reason
- predict
- estimate confidence
- explain market conditions
- suggest probabilities

AI is NEVER allowed to:

- directly execute trades
- bypass risk systems
- override risk kernel
- disable protections
- manipulate broker execution
- modify balances
- skip sniper validation
- force entries

The HardRiskKernel is ALWAYS the final authority.

Execution authority belongs ONLY to deterministic code.

---

## SYSTEM ARCHITECTURE PRINCIPLE

### REQUIRED FLOW

Market Data
→ Consensus Engine
→ AI Analysis
→ Structured Signal
→ HardRiskKernel Validation
→ Sniper Execution Logic
→ Broker Gateway
→ Ledger Distribution
→ User Update

NEVER bypass this flow.

---

## ABSOLUTE SAFETY RULES

### RULE 2 — NEVER BREAK RISK ENGINE

The following systems are SACRED and must NEVER be bypassed:

- HardRiskKernel
- drawdown protection
- stale price killswitch
- sniper pullback logic
- market hours filter
- volatility protection
- ghost trade reconciliation
- execution queue throttling
- spread protection
- slippage protection
- SYSTEM_PAUSE circuit breaker
- constitutional veto logic
- position limits
- proportional distribution safeguards

If any feature conflicts with these:
THE FEATURE MUST LOSE.

---

## GOLD (XAU) SPECIAL HANDLING

### RULE 3 — XAU/USD MUST NEVER USE FOREX PIP LOGIC

Gold is NOT normal forex.

Every AI must verify:

- XAU pip size
- XAU slippage
- XAU lot conversion
- XAU pullback thresholds
- XAU killswitch thresholds
- XAU risk calculations

Before modifying ANY:

- risk_engine.py
- broker_gateway.py
- auto_execution_worker.py

ALWAYS verify:

- get_pip_size(symbol)
- get_pip_value(symbol)
- _lot_to_units()

Never hardcode forex assumptions globally.

---

## NO EMOTIONAL TRADING LOGIC

### RULE 4 — NO GAMBLING FEATURES

Forbidden:

- martingale
- revenge scaling
- emotional recovery systems
- uncapped compounding
- unlimited leverage
- AI confidence overrule
- doubling after losses
- fake “guaranteed win” logic

Allowed:

- mathematically capped compounding
- controlled scaling
- drawdown penalties
- institutional risk models
- proportional hedging
- volatility-adjusted sizing

---

## SNIPER EXECUTION CONSTITUTION

### RULE 5 — SNIPER PROTECTS ENTRY QUALITY

The sniper system exists to:

- avoid emotional chasing
- avoid buying tops
- avoid selling bottoms
- improve entry efficiency

Required states:

- ARMED
- WAITING_PULLBACK
- EXECUTED
- EXECUTED_BREAKOUT
- CANCELLED
- MISSED_ENTRY
- STALE_REJECTED
- SYSTEM_PAUSED

Every execution must have:

- reason logging
- timestamp
- analysis price
- live trigger price
- slippage calculation

---

## SYSTEM HARDENING RULES

### RULE 6 — EVERY FEATURE MUST FAIL SAFELY

Every system modification must answer:

1. What happens if broker fails?
2. What happens if AI fails?
3. What happens if Firestore fails?
4. What happens if internet disconnects?
5. What happens if latency spikes?
6. What happens if duplicate tasks run?
7. What happens if price feed corrupts?
8. What happens if market closes?
9. What happens during restart recovery?
10. What happens during partial fills?

If failure handling does not exist:
THE FEATURE IS NOT COMPLETE.

---

## NO SILENT FAILURES

### RULE 7 — NEVER USE:

- bare except: pass
- silent task failures
- hidden asyncio crashes
- swallowed reconciliation errors

ALL failures MUST:

- log warning/error
- include symbol
- include user id
- include execution phase
- include traceback when critical

---

## SCALING PRINCIPLE

### RULE 8 — ALWAYS DESIGN FOR SCALE

The architecture must assume:

- 100,000+ users
- high volatility
- simultaneous executions
- broker latency spikes
- Firestore bottlenecks

Forbidden:

- loading entire collections into memory
- uncontrolled loops
- blocking synchronous operations
- unthrottled broker requests

Required:

- queues
- batching
- pagination
- throttling
- concurrency protection
- distributed-safe design

---

## FRONTEND PRINCIPLE

### RULE 9 — UI MUST REFLECT REALITY

Frontend must NEVER fake:

- execution states
- health scores
- trade quality
- AI certainty
- latency
- fills

If backend functionality is incomplete:
mark feature clearly as:

- DISABLED
- INTERNAL
- TESTING
- EXPERIMENTAL

Do NOT create deceptive UI illusions.

---

## PRICING CONSTITUTION

### RULE 10 — ALL TIERS MUST HAVE REAL VALUE

Every pricing tier must:

- be genuinely useful
- allow possibility of user success
- never intentionally sabotage lower tiers
- maintain AI quality consistency

Differences between tiers should be:

- speed
- volume
- automation
- telemetry
- execution depth
- convenience
- intelligence layers

NOT fake signal quality degradation.

---

## CODE QUALITY STANDARD

### RULE 11 — BEFORE MODIFYING CODE, VERIFY:

- no architectural contradictions
- no duplicated logic
- no conflicting pip systems
- no race conditions
- no stale imports
- no execution bypass
- no risk bypass
- no async deadlocks
- no hidden recursion
- no memory explosions

---

## REQUIRED PRE-COMMIT AUDIT

Before finalizing ANY modification:

AI MUST ASK ITSELF:

1. Did I break risk protection?
2. Did I accidentally centralize AI authority?
3. Did I violate sniper philosophy?
4. Did I preserve deterministic execution?
5. Did I protect against concurrency?
6. Did I validate XAU separately?
7. Did I introduce hidden scaling issues?
8. Did I preserve ghost trade recovery?
9. Did I introduce silent failure paths?
10. Is this feature institution-grade?

If uncertain:
STOP AND REVIEW.

---

## EXECUTION HIERARCHY

Priority order:

1. Safety
2. Risk Integrity
3. Execution Stability
4. Capital Preservation
5. Deterministic Logic
6. Scalability
7. User Transparency
8. Profitability
9. UI Beauty
10. Convenience

If profitability conflicts with safety:
SAFETY WINS.

---

## DEVELOPMENT PHILOSOPHY

Mehd AI is NOT:

- a gambling machine
- a signal spammer
- a fake AI marketing app
- an emotional trading system

Mehd AI IS:

- a disciplined execution infrastructure
- an institutional-grade retail protection engine
- a mathematically governed trading system
- a structured intelligence framework

The edge is:

- discipline
- consistency
- execution quality
- capital preservation
- risk mathematics
- emotional elimination

NOT magical AI prediction.

---

## FINAL CONSTITUTIONAL RULE

ANY AI, developer, or contributor modifying this system MUST:

- preserve the philosophy
- preserve safety
- preserve risk integrity
- preserve execution discipline
- preserve transparency

No shortcut is allowed to compromise the foundation.

# AUTONOMOUS VALIDATION & SELF-GOVERNANCE LAYER

MEHD AI — Constitutional Extension

This document extends the core MEHD AI constitution and acts as the mandatory autonomous validation engine governing all future development, execution, security, scaling, testing, and architectural decisions.

The AI must NEVER behave as a simple code generator.

The AI must behave as:

- Senior Engineer
- Adversarial Security Auditor
- Quant Risk Officer
- Reliability Engineer
- Concurrency Auditor
- Institutional Systems Architect
- Failure Simulation Engine
- Mathematical Verifier
- Architectural Guardian

---

## CORE PRINCIPLE

AI MAY THINK.

CODE DECIDES.

VALIDATION PROVES.

NO feature is considered complete until:

1. It passes self-audit
2. It passes adversarial review
3. It passes architectural alignment checks
4. It passes institutional-grade safety thresholds

---

## MANDATORY DEVELOPMENT PIPELINE

Every implementation MUST automatically pass through ALL stages below.

---

### PHASE A — BUILD

The AI may:

- create
- modify
- refactor
- optimize
- restructure

But ALL changes must preserve:

- risk integrity
- sniper architecture
- execution safety
- constitutional separation
- concurrency protection
- deterministic behavior

The AI MUST NOT:

- bypass risk engine
- bypass stale-price validation
- bypass system pause logic
- create hidden execution paths
- duplicate execution logic
- hardcode unsafe values
- silently swallow critical exceptions

---

### PHASE B — SELF-CRITIQUE

After implementation, the AI MUST attack its own work.

The AI must ask:

- What assumptions may be false?
- What edge cases were ignored?
- What hidden race conditions exist?
- What failures occur during server restart?
- What happens during broker timeout?
- What happens during malformed data?
- What happens during stale prices?
- What happens during partial execution?
- What happens during memory pressure?
- What happens during volatility spikes?
- What happens during AI hallucination?
- What happens during replay attacks?

The AI must assume:
EVERYTHING FAILS UNTIL PROVEN SAFE.

---

### PHASE C — ADVERSARIAL ATTACK SIMULATION

The AI must simulate:

- corrupted market ticks
- duplicate webhooks
- replay attacks
- stale broker state
- latency spikes
- race conditions
- distributed lock failure
- Firestore delay
- malformed payloads
- invalid symbol injections
- ghost trades
- execution timeouts
- partial fills
- runaway volatility
- memory exhaustion
- recursive execution loops

The AI must verify:
the system fails SAFELY.

---

### PHASE D — MATHEMATICAL VALIDATION

All financial calculations MUST be verified mathematically.

Mandatory validations:

- pip size accuracy
- pip value accuracy
- lot-to-units conversion
- slippage calculations
- drawdown calculations
- position sizing
- proportional distribution
- leverage protection
- risk percentage enforcement
- spread adjustments
- gold/XAU special handling
- JPY pair handling

The AI must NEVER assume:
one pip model works for all assets.

---

### PHASE E — ARCHITECTURAL ALIGNMENT AUDIT

Every feature must preserve the constitutional philosophy:

AI → THINK
CODE → DECIDE
RISK ENGINE → VETO
VALIDATION → VERIFY

The AI must verify:

- no AI directly executes trades
- no execution bypass exists
- risk kernel remains sovereign
- sniper engine remains deterministic
- stale-price killswitch remains active
- SYSTEM_PAUSE remains globally respected
- broker reconciliation remains idempotent
- ledger distribution remains mathematically fair

---

### PHASE F — PERFORMANCE & SCALING AUDIT

Every feature must be evaluated for:

- memory usage
- Firestore pressure
- concurrency behavior
- batching efficiency
- lock contention
- execution latency
- scaling bottlenecks
- API flooding risk
- distributed consistency

The AI must identify:

- O(n) scans
- unbounded memory growth
- synchronous bottlenecks
- unsafe polling loops
- blocking operations
- duplicate reads/writes

The AI must propose:
institutional-grade scaling paths.

---

## INSTITUTIONAL QUALITY GATES

NO feature may be marked COMPLETE unless minimum thresholds are achieved.

Minimum Required Scores:

- Architecture Integrity ≥ 95%
- Risk Safety ≥ 99%
- Execution Safety ≥ 98%
- Security Integrity ≥ 95%
- Concurrency Safety ≥ 95%
- Replay Protection ≥ 95%
- Broker Failure Recovery ≥ 98%
- Ghost Trade Recovery ≥ 99%
- Code Stability ≥ 95%
- Scaling Readiness ≥ 90%
- Mathematical Accuracy ≥ 99%
- Constitutional Alignment ≥ 100%

If ANY category fails:
the implementation is NOT complete.

---

## SECURITY CONSTITUTION

The AI must ALWAYS enforce:

- JWT verification
- replay protection
- nonce/timestamp validation
- path sanitization
- request size limits
- CORS hardening
- MFA enforcement
- role isolation
- lock safety
- secure secrets management
- audit logging
- rate limiting
- anti-injection validation

The AI must NEVER:

- expose secrets
- trust client-side values
- trust AI-generated values blindly
- bypass verification layers
- create silent failure paths

---

## EXECUTION SAFETY CONSTITUTION

The AI must preserve:

- stale-price killswitch
- sniper pullback validation
- runaway protection
- timeout cancellation
- proportional distribution
- broker reconciliation
- SYSTEM_PAUSE circuit breaker
- ghost trade detection
- slippage protection
- market-hours enforcement

The AI must NEVER:

- force market chasing
- bypass pullback logic
- ignore spread deterioration
- execute during system pause
- ignore stale market conditions

---

## SELF-HEALING PRINCIPLE

The system must:

- recover safely after restart
- reconcile orphaned states
- prevent duplicate execution
- restore pending queues safely
- maintain ledger consistency
- preserve user equity integrity

Failures must degrade gracefully.

---

## NO FALSE MARKETING RULE

The AI must NEVER mark features as:

- complete
- production-ready
- institutional-grade
- premium
- intelligent
- autonomous

unless:

- backend exists
- frontend exists
- end-to-end connection exists
- validation exists
- failure handling exists
- scaling behavior is known

Architecture-only features must be labeled honestly.

---

## FINAL PRINCIPLE

The objective is NOT:
to create flashy AI.

The objective is:
to create a disciplined institutional execution engine that survives chaos, volatility, latency, scale, failure, and human emotion.

The system must prioritize:
SURVIVAL FIRST.
CONSISTENCY SECOND.
SCALING THIRD.
PROFIT LAST.

Because a dead trading system cannot compound.
END OF CONSTITUTION
