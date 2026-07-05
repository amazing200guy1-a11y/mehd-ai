MEHD AI — ARCHITECTURE_DISCIPLINE.md

PURPOSE:
This file defines the permanent architectural discipline, modular engineering standards, payment separation philosophy, maintainability doctrine, and anti-entropy rules for MEHD AI.

The goal is to ensure:

- scalable architecture
- clean maintainability
- modular systems
- low regression risk
- production-grade organization
- institutional engineering discipline

This doctrine exists to PREVENT:

- architectural decay
- giant unmaintainable files
- mixed responsibilities
- hidden technical debt
- UI/business logic coupling
- unstable feature expansion
- payment compliance mistakes
- AI-generated chaos

====================================================
GLOBAL EXECUTION DIRECTIVE

Before implementing ANY feature or modification:

1. Read:

- COMPULSORY.md
- PRODUCTION_STANDARDS.md
- RED_TEAM_PROTOCOL.md
- ARCHITECTURE_DISCIPLINE.md
- HISTORICAL_FAILURES.md
- SCALING_FAILURE_PATTERNS.md

The AI must continuously study:

- historical platform failures
- fintech collapses
- broker execution disasters
- security breach patterns
- scaling bottlenecks
- concurrency failures
- UI/UX degradation patterns
- payment compliance violations
- infrastructure outages
- race condition incidents
- catastrophic technical debt accumulation

The AI should learn from:

- Spotify architecture scaling philosophy
- YouTube infrastructure resilience philosophy
- Stripe payment isolation philosophy
- Netflix reliability engineering philosophy
- Amazon fault-tolerant systems philosophy
- institutional fintech risk segregation models

The goal is NOT to copy these companies directly.

The goal is to adopt:

- engineering discipline
- modular architecture
- fault tolerance
- scalability thinking
- resilience patterns
- maintainability standards
- operational maturity
- infrastructure professionalism

Every new implementation must ask:

- Could this architecture survive millions of users?
- Could this fail safely under stress?
- Would this create technical debt later?
- Would this scale cleanly?
- Is this resilient against human mistakes?
- Is this resilient against AI-generated chaos?

2. Analyze:

- architectural impact
- maintainability impact
- scalability impact
- responsiveness impact
- payment/compliance impact
- modularity impact

3. Refuse architectural shortcuts.

4. Refuse “temporary hacks” that create future instability.

5. Continuously refactor toward:

- modularity
- separation of concerns
- reusable systems
- cleaner abstractions
- simpler maintenance

====================================================
CORE ARCHITECTURE PHILOSOPHY

MEHD AI must behave like:

- a production-grade operating system
- institutional infrastructure
- a scalable execution ecosystem

NOT:

- a hacked-together startup prototype
- a giant spaghetti-code project
- a chaotic AI-generated codebase

Every system must remain:

- understandable
- testable
- maintainable
- modular
- scalable
- professionally structured

====================================================
SEPARATION OF CONCERNS

UI files MUST NOT:

- contain business logic
- contain pricing logic
- contain entitlement logic
- contain broker logic
- contain security logic
- contain execution logic
- contain hardcoded feature permissions

UI should primarily:

- render
- display
- interact
- forward events

Business logic belongs in:

- services
- managers
- controllers
- providers
- backend APIs
- centralized configuration systems

====================================================
FILE SIZE & RESPONSIBILITY RULES

Large files are WARNING SIGNS.

If a file:

- mixes multiple responsibilities
- becomes difficult to reason about
- contains unrelated logic
- exceeds maintainability boundaries

the AI must:

- refactor
- modularize
- extract components
- isolate logic
- split services

Examples of dangerous mixing:

- pricing + UI + state + API + entitlement logic
- broker execution + UI rendering
- chart rendering + AI orchestration
- security + frontend presentation

====================================================
PAYMENT & SUBSCRIPTION ARCHITECTURE

MEHD AI uses:
EXTERNAL WEB-BASED BILLING.

The app is NOT designed around:

- Apple In-App Purchases
- Google Play Billing
- embedded native payment systems

Subscription flow philosophy:

1. User subscribes externally:

- website
- landing page
- secure checkout flow

2. Backend updates entitlement state.

3. Mobile app syncs subscription access from backend.

The app should primarily:

- display subscription status
- display current plan
- display entitlement state
- allow account management
- redirect users to web billing portal

====================================================
STRICT PAYMENT RULES

The mobile app must NOT:

- directly process subscription purchases
- hardcode platform purchase flows
- embed native IAP assumptions
- tightly couple pricing logic to UI
- expose sensitive billing logic in frontend

Avoid:

- giant subscription purchase screens
- direct native checkout assumptions
- duplicated pricing constants
- billing logic scattered across UI files

====================================================
ENTITLEMENT ARCHITECTURE

All plan permissions should come from:

- centralized entitlement systems
- backend validation
- feature registries
- subscription managers

NOT:

- scattered if-statements
- hardcoded tier checks across screens
- duplicated plan logic
- frontend-only gating

The frontend should trust:

- authenticated entitlement state
- backend subscription verification

====================================================
ANTI-ENTROPY RULES

The AI must actively prevent:

- duplicated logic
- duplicated constants
- repeated pricing values
- inconsistent naming
- dead code accumulation
- unused widgets
- abandoned services
- disconnected states
- orphaned components

Continuously clean:

- stale code
- broken abstractions
- unnecessary complexity
- redundant wrappers
- duplicated business logic

====================================================
UI/UX ARCHITECTURE DISCIPLINE

The interface must remain:

- calm
- organized
- structured
- professional
- predictable
- responsive

Avoid:

- overcrowded layouts
- excessive modal stacking
- chaotic navigation
- hidden actions
- inaccessible workflows
- inconsistent spacing
- random animation behavior

====================================================
RESPONSIVENESS & DEVICE CONSISTENCY

Every screen must function properly on:

- low-end phones
- modern phones
- tablets
- laptops
- desktops
- ultra-wide monitors

Prevent:

- overflow warnings
- clipped layouts
- hidden buttons
- inaccessible controls
- broken scaling
- unresponsive interactions

Every important action must remain:

- visible
- reachable
- intuitive

====================================================
BUTTON & INTERACTION RULES

Every visible button MUST:

- work correctly
- trigger expected behavior
- provide proper feedback
- handle loading safely
- handle failure safely

The system must NEVER contain:

- fake buttons
- dead interactions
- placeholder production actions
- misleading controls

====================================================
STATE MANAGEMENT DISCIPLINE

Prevent:

- duplicated state
- conflicting state ownership
- hidden state mutation
- unsafe async updates
- race-condition-prone state logic

Favor:

- centralized state ownership
- predictable updates
- clean async handling
- observable flows
- recoverable state transitions

====================================================
AI-GENERATED CODE DISCIPLINE

The AI must continuously ask:

- Does this increase complexity unnecessarily?
- Can this be modularized further?
- Is responsibility properly separated?
- Is this maintainable long-term?
- Is logic duplicated elsewhere?
- Will future scaling become difficult?
- Is this introducing hidden technical debt?
- Is this architecture institutionally clean?

If uncertainty exists:
continue refinement.

====================================================
FINAL DIRECTIVE

MEHD AI is NOT being engineered as:

- a temporary prototype
- a rushed startup demo
- a hype-driven trading app

It is being engineered as:

- institutional-grade infrastructure
- a scalable trading operating system
- a disciplined execution ecosystem
- a long-term resilient platform

Every implementation decision must prioritize:

- clarity
- maintainability
- professionalism
- scalability
- resilience
- architectural cleanliness
- operational maturity
