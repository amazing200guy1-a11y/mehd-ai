# MEHD AI Institutional Failure Intelligence Constitution

## CORE PURPOSE

This document exists to force Mehd AI to learn from the historical failures, hacks, collapses, outages, scaling disasters, architectural mistakes, and trust failures of major technology companies, trading firms, broker systems, exchanges, and financial infrastructure platforms.

The goal is NOT to build a “perfect” or “unhackable” system.

The goal is to build a system that:

- fails safely
- detects anomalies early
- limits blast radius
- freezes safely
- reconciles correctly
- self-heals where possible
- survives partial failure
- protects user capital above all else

This file must be consulted BEFORE:

- creating new features
- modifying execution logic
- changing risk systems
- changing storage architecture
- changing broker logic
- changing autopilot flows
- changing scaling systems
- changing concurrency logic
- changing authentication/security logic
- changing Firestore synchronization
- changing queue systems
- changing latency-sensitive systems

---

## PRIMARY PHILOSOPHY

AI THINKS.
CODE DECIDES.
RISK ENGINE VETOES.
EXECUTION REMAINS DETERMINISTIC.

NO AI MODEL MAY:

- directly execute trades
- bypass risk systems
- bypass broker verification
- bypass sniper verification
- override safety systems
- override stale-price killswitches
- override system pause states

The HardRiskKernel remains the final authority.

---

## HISTORICAL FAILURE ANALYSIS REQUIREMENT

Before implementing ANY system change, the AI must analyze:

1. Has a similar architecture failed historically?
2. What caused the failure?
3. Could this happen inside Mehd AI?
4. What is the blast radius if it fails?
5. How is the failure detected?
6. How is the failure contained?
7. How is the system recovered?
8. How are users protected during failure?
9. How is corrupted state reconciled?
10. What assumptions are currently unverified?

---

## REQUIRED FAILURE SIMULATIONS

The AI MUST adversarially simulate:

### EXECUTION FAILURES

- broker timeouts
- partial fills
- stale market data
- ghost trades
- duplicate executions
- runaway markets
- sniper timeout scenarios
- slippage spikes
- spread explosions
- invalid tick data
- rejected orders
- delayed broker receipts

### INFRASTRUCTURE FAILURES

- websocket disconnects
- Firestore delayed writes
- storage corruption
- server restart during execution
- partial backend crashes
- queue overflow
- memory exhaustion
- event-loop stalls
- lock desynchronization
- distributed race conditions

### SECURITY FAILURES

- replay attacks
- spam requests
- API abuse
- forged payloads
- JWT manipulation
- privilege escalation
- endpoint flooding
- malformed request injection
- data poisoning
- prompt injection attempts
- LLM hallucination abuse

### SCALING FAILURES

- 10 users
- 100 users
- 1,000 users
- 10,000 users
- 5,000,000 users

The AI must estimate:

- memory pressure
- queue latency
- broker pressure
- Firestore bottlenecks
- execution delay
- synchronization risks

---

## KNOWN HISTORICAL LESSONS

### FACEBOOK LESSON
Over-centralized permissions create catastrophic trust failures.
**MEHD AI RULE:**
- strict permission boundaries
- no universal bypass
- role isolation
- audit logging required

### GOOGLE LESSON
Scaling bottlenecks appear slowly, then collapse suddenly.
**MEHD AI RULE:**
- avoid loading massive collections fully into memory
- paginate aggressively
- batch safely
- monitor execution latency continuously

### BINANCE LESSON
Hot execution systems require layered protection.
**MEHD AI RULE:**
- execution throttling mandatory
- stale-price verification mandatory
- sniper verification mandatory
- killswitches mandatory

### ROBINHOOD LESSON
Infrastructure overload destroys trust instantly.
**MEHD AI RULE:**
- graceful degradation required
- system pause required
- queue protection required
- broker rate limiting required

### FTX LESSON
Fake risk management eventually collapses everything.
**MEHD AI RULE:**
- no hidden overrides
- no emotional execution
- no manual bypass of risk engine
- all risk decisions must be mathematical

### CLOUD OUTAGE LESSON
Partial failures are more dangerous than full failures.
**MEHD AI RULE:**
- every subsystem must validate state independently
- reconciliation loops mandatory
- orphan recovery mandatory
- idempotency mandatory

---

## SYSTEM HARDENING REQUIREMENTS

ALL NEW FEATURES MUST:
- support graceful failure
- support rollback safety
- support state reconciliation
- support timeout recovery
- support concurrency protection
- support audit logging
- support deterministic execution
- support security validation
- support scaling verification

NO FEATURE MAY:
- silently fail
- bypass logging
- use bare except: pass
- bypass sniper logic
- bypass HardRiskKernel
- bypass telemetry
- bypass throttling
- bypass stale-price validation

---

## AUTOPILOT SURVIVABILITY RULES

The autopilot must ALWAYS:
- prefer survival over profit
- cancel unsafe trades
- freeze under uncertainty
- avoid chasing markets
- avoid overleveraging
- reject corrupted data
- reject unrealistic prices
- reject stale signals
- reject extreme volatility conditions

If uncertainty exists:
**SYSTEM MUST DEFAULT TO SAFETY.**

---

## RED TEAM REQUIREMENT

Every implementation must undergo:
1. Adversarial Review
2. Concurrency Review
3. Scaling Review
4. Security Review
5. Mathematical Validation
6. Broker Failure Simulation
7. Frontend/Backend Synchronization Validation
8. User Experience Integrity Validation

---

## USER TRUST RULE

The UI MUST NEVER:
- fake execution states
- fake live prices
- fake confidence
- fake completion
- fake synchronization
- hide failures silently

If something fails:
- show it honestly
- explain it clearly
- recover safely

---

## FINAL PRINCIPLE

Mehd AI is NOT designed to:
- gamble
- chase markets
- maximize emotional excitement

Mehd AI is designed to:
- survive
- execute consistently
- protect capital
- scale safely
- fail gracefully
- operate institutionally

**SURVIVAL FIRST.**
**PRECISION SECOND.**
**SCALING THIRD.**
**PROFIT FOURTH.**
