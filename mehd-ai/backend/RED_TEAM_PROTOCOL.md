# MEHD AI — RED TEAM PROTOCOL

File Name: RED_TEAM_PROTOCOL.md

## PURPOSE:
This file defines the permanent adversarial testing, stress testing, resilience validation, and self-auditing doctrine for MEHD AI.

The objective is to ensure:
- production-grade survivability
- security hardening
- execution reliability
- infrastructure resilience
- cross-device stability
- institutional-grade robustness

This protocol assumes:
**EVERYTHING CAN FAIL.**

The system must continuously attempt to:
- discover weaknesses
- simulate attacks
- simulate failures
- stress infrastructure
- detect regressions
- uncover hidden instability
- eliminate silent failure paths

---

## GLOBAL EXECUTION DIRECTIVE

BEFORE starting ANY implementation task:

1. Read:
- COMPULSORY.md
- PRODUCTION_STANDARDS.md
- RED_TEAM_PROTOCOL.md

2. Establish internal quality targets for:
- security
- stability
- responsiveness
- professionalism
- resilience
- scalability
- execution safety

3. Define a completion threshold BEFORE coding begins.

4. Continuously self-audit during implementation.

5. AFTER implementation:
- re-run all audits
- re-check all constitutions
- re-evaluate edge cases
- re-test UI integrity
- re-test execution safety

If standards are NOT met:
**DO NOT finalize the task.**
Continue refining until targets are achieved.

---

## CORE RED TEAM PHILOSOPHY

Assume:
- APIs fail
- brokers timeout
- users spam endpoints
- Firestore delays writes
- AI returns malformed output
- devices lag
- networks disconnect
- attackers manipulate inputs
- race conditions exist
- state becomes corrupted
- execution order breaks
- charts desync
- partial failures occur

The objective is NOT:
“Does it work?”

The objective is:
**“Does it survive failure safely?”**

---

## MANDATORY ADVERSARIAL TESTING

Every critical system must be tested against:
- stale prices
- replay attacks
- malformed payloads
- timeout conditions
- partial execution
- websocket disconnects
- duplicated requests
- race conditions
- rapid state changes
- corrupted market data
- memory pressure
- Firestore delays
- broker rejection
- unauthorized access attempts
- invalid authentication
- concurrent execution storms
- scaling bottlenecks
- UI interaction spam
- extreme latency
- device responsiveness failures

---

## AUTOPILOT HARDENING RULES

The autopilot system must ALWAYS:
- fail safely
- freeze safely
- reconcile safely
- recover safely
- reject uncertainty
- reject stale execution
- reject corrupted states

The autopilot must NEVER:
- execute blindly
- bypass risk validation
- ignore broker uncertainty
- ignore stale prices
- ignore reconciliation failures

---

## UI & UX RED TEAMING

Continuously validate:
- every button works
- no dead interactions
- no hidden controls
- no overflow warnings
- no broken layouts
- no inaccessible workflows
- no animation lag
- no inconsistent state rendering

Test across:
- low-end phones
- tablets
- laptops
- desktop screens
- ultra-wide displays

---

## SCALING & LOAD TESTING

Continuously simulate:
- 10 users
- 100 users
- 1,000 users
- 10,000 users

Validate:
- queue stability
- execution fairness
- memory usage
- Firestore throughput
- lock integrity
- broker request pacing
- latency spikes
- task recovery

No scaling assumption should remain untested.

---

## SECURITY HARDENING

Continuously inspect for:
- replay attack vectors
- privilege escalation
- unsafe logging
- insecure defaults
- token leakage
- injection attacks
- broken authorization
- exposed secrets
- state desynchronization
- race-condition exploits

All sensitive systems must:
- validate ownership
- validate timestamps
- validate permissions
- validate execution state
- reject invalid transitions

---

## SELF-AUDIT LOOP

Before marking ANY task complete, the AI must ask:
- Did this introduce instability?
- Did this break responsiveness?
- Did this weaken security?
- Did this create hidden technical debt?
- Did this introduce race conditions?
- Did this create silent failures?
- Did this reduce professionalism?
- Did this increase system complexity unnecessarily?
- Does this survive partial failure?
- Does this fail safely?
- Does this remain institutionally consistent?

If uncertainty exists:
**continue refinement.**

---

## MANDATORY COMPLETION THRESHOLDS

Tasks should internally target:
- Security Confidence: **98%+**
- Execution Stability: **98%+**
- Cross-Device Reliability: **98%+**
- Failure Recovery: **95%+**
- Scalability Confidence: **95%+**
- UI Integrity: **95%+**
- Professionalism: **95%+**
- Institutional Consistency: **95%+**

No implementation should be considered complete below threshold.

---

## FINAL DIRECTIVE

MEHD AI is being engineered as:
- a resilient execution ecosystem
- a production-grade trading operating system
- a protection-first institutional infrastructure
- a mathematically disciplined automation environment

The objective is NOT rapid feature quantity.

The objective is:
- survivability
- trustworthiness
- execution discipline
- infrastructure maturity
- long-term operational stability

The system must continuously evolve toward:
- stronger resilience
- safer execution
- cleaner architecture
- deeper reliability
- institutional-grade robustness

---

## MEHD AI AUDIT OVERRIDES

The auditor MUST respect the architectural philosophy of MEHD AI.

The goal is NOT:
- endless refactoring
- unnecessary rewrites
- destroying stable systems
- replacing working architecture unnecessarily

The goal IS:
- stability
- hardening
- resilience
- production polish
- scalability
- safety
- maintainability

---

### ARCHITECTURE PROTECTION RULE

Before modifying any system, the auditor must determine:
- Is the existing architecture already stable?
- Would this refactor increase risk unnecessarily?
- Would this create downstream regressions?
- Would this reduce maintainability?
- Is the issue truly critical or merely stylistic?

The auditor must prioritize:
- preserving stability
- preserving modularity
- preserving production reliability

over:
- cosmetic rewrites
- unnecessary abstractions
- “perfect code” obsession

---

### MEHD AI CRITICAL SYSTEMS

The following systems are HIGH-RISK and require extreme caution:
- risk_engine.py
- auto_execution_worker.py
- broker_gateway.py
- consensus_engine.py
- ConstitutionManager
- payment entitlement systems
- authentication middleware
- autopilot execution pipeline
- ledger distribution systems
- concurrency and locking systems

For these systems:
- avoid unnecessary rewrites
- avoid aggressive refactors
- preserve behavioral integrity
- preserve mathematical correctness
- preserve execution determinism

---

### NO FALSE POSITIVES RULE

The auditor must NOT:
- invent fake vulnerabilities
- force trendy patterns unnecessarily
- over-engineer stable systems
- classify preferences as critical issues

Every finding must include:
- actual risk
- actual impact
- actual reasoning
- actual downstream effect

---

### UI/UX HARDENING STANDARD

The auditor must aggressively detect:
- RenderFlex overflow
- clipped widgets
- inaccessible controls
- dead buttons
- broken navigation
- missing loading states
- inconsistent spacing
- mobile layout failures
- tablet layout failures
- web responsiveness failures
- fake interactions
- broken animation states

The target UX is:
- calm
- institutional
- responsive
- polished
- professional
- production-grade

---

### PAYMENT & PLATFORM RULES

MEHD AI uses:
- external website subscriptions
- entitlement synchronization
- NO native in-app purchase dependency

The auditor must prevent:
- accidental App Store billing coupling
- scattered pricing logic
- hardcoded subscription states
- entitlement inconsistencies

---

### FINAL AUDITOR DIRECTIVE

The auditor's responsibility is to transform MEHD AI into:
- hardened infrastructure
- resilient production software
- scalable architecture
- institutional-grade UX
- disciplined engineering systems

The auditor must continue cycling until:
- regression risk is low
- UI polish is high
- responsiveness is stable
- architecture is disciplined
- security posture is hardened
- operational quality is production-grade
