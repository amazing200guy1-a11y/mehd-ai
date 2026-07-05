# MEHD AI — SCALING FAILURE PATTERNS

File Name: SCALING_FAILURE_PATTERNS.md

## PURPOSE

This file defines the permanent scaling failure patterns, bottleneck prevention rules, resource management discipline, and infrastructure growth philosophy for MEHD AI.

The objective is to ensure:

- predictable scaling behavior
- resource-efficient architecture
- bottleneck prevention
- graceful degradation under load
- infrastructure cost discipline
- operational survivability at scale

This doctrine exists to PREVENT:

- sudden infrastructure collapse
- cascading failure propagation
- runaway resource consumption
- undetected scaling bottlenecks
- cost explosion from inefficient patterns
- user-impact from capacity failures

====================================================
HISTORICAL SCALING FAILURES — LESSONS APPLIED

### PATTERN 1 — UNBOUNDED COLLECTION LOADING
**Failure**: Loading entire Firestore collections into memory.
**Blast Radius**: Memory exhaustion → server crash → all users affected.
**MEHD AI RULE**:
- ALWAYS paginate Firestore queries
- NEVER use `stream.toList()` on unbounded collections
- Set explicit `.limit()` on every query
- Monitor document count growth

### PATTERN 2 — SYNCHRONOUS BROKER STORMS
**Failure**: Sending broker API calls synchronously for all users.
**Blast Radius**: Linear latency growth → timeout cascades → ghost trades.
**MEHD AI RULE**:
- Use execution queues with configurable concurrency limits
- Implement broker request pacing (max N requests/second)
- Use `asyncio.Semaphore` for concurrent execution control
- Never fire-and-forget broker requests

### PATTERN 3 — UNCONTROLLED POLLING LOOPS
**Failure**: Fixed-interval polling that scales linearly with user count.
**Blast Radius**: API rate limit exhaustion → cascading failures.
**MEHD AI RULE**:
- Prefer event-driven (webhooks, SSE) over polling
- If polling is required, use adaptive intervals
- Implement backoff on consecutive empty responses
- Share polling results across users where possible

### PATTERN 4 — LOCK CONTENTION AT SCALE
**Failure**: Single global lock for all user operations.
**Blast Radius**: Serialized execution → queue backup → stale executions.
**MEHD AI RULE**:
- Use per-user or per-symbol locks, never global locks
- Set lock timeouts to prevent deadlocks
- Monitor lock wait times as a scaling metric
- Implement lock-free patterns where possible

### PATTERN 5 — FIRESTORE WRITE HOTSPOTS
**Failure**: All users writing to the same document simultaneously.
**Blast Radius**: Firestore write contention → data loss → inconsistency.
**MEHD AI RULE**:
- Use per-user document paths
- Batch writes where possible
- Avoid counters on shared documents (use distributed counters)
- Monitor Firestore 500-level error rates

### PATTERN 6 — MEMORY LEAK ACCUMULATION
**Failure**: Unclosed connections, growing caches, leaked asyncio tasks.
**Blast Radius**: Gradual memory pressure → OOM kill → unclean restart.
**MEHD AI RULE**:
- Always close HTTP sessions and websocket connections
- Use bounded caches (LRU with max size)
- Track and cancel all spawned asyncio tasks on shutdown
- Monitor process RSS memory over time

### PATTERN 7 — CASCADING RETRY STORMS
**Failure**: Every client retrying simultaneously after a transient failure.
**Blast Radius**: Thundering herd → backend overload → extended outage.
**MEHD AI RULE**:
- Use exponential backoff with jitter on all retries
- Implement circuit breakers for external dependencies
- Set maximum retry counts (not infinite loops)
- Use client-side retry budgets

### PATTERN 8 — COST EXPLOSION FROM AI CALLS
**Failure**: Uncontrolled OpenAI API calls per user action.
**Blast Radius**: Exponential cost growth → budget exhaustion.
**MEHD AI RULE**:
- Enforce per-user daily analysis limits (tier-gated)
- Cache AI responses for identical market conditions
- Use token counting before sending requests
- Monitor daily API spend with automatic alerts

====================================================
SCALING CAPACITY TARGETS

The architecture must be validated at:

| Scale | Users | Expected Behavior |
|-------|-------|-------------------|
| Seed | 10 | No bottlenecks |
| Early | 100 | No contention |
| Growth | 1,000 | Queued execution |
| Scale | 10,000 | Graceful degradation |
| Institutional | 5,000,000+ | Horizontal scaling |

At every scale tier, the system must:

- maintain execution latency < 2 seconds
- maintain Firestore read latency < 500ms
- maintain memory usage linear (not exponential)
- maintain broker request pacing
- maintain queue fairness across users

====================================================
MANDATORY SCALING CHECKS

Before deploying ANY feature, verify:

1. Does this scale linearly or worse?
2. Is there a bounded maximum resource consumption?
3. Is there a queue or throttle for concurrent operations?
4. Is Firestore query complexity bounded?
5. Are external API calls rate-limited?
6. Is memory usage predictable under load?
7. Are retries bounded with backoff?
8. Is graceful degradation implemented?
9. Are locks scoped narrowly (per-user, per-symbol)?
10. Is there a circuit breaker for external dependencies?

If ANY answer is uncertain:
**DO NOT DEPLOY. Continue hardening.**

====================================================
RESOURCE MANAGEMENT RULES

### MEMORY
- All caches must have maximum size limits
- All collections loaded from DB must be paginated
- All background tasks must be tracked and cancellable
- All websocket connections must have keepalive + cleanup

### NETWORK
- All HTTP clients must use connection pooling
- All external API calls must have timeouts
- All retries must use exponential backoff with jitter
- All broker requests must be paced

### STORAGE
- All Firestore queries must use `.limit()`
- All write operations must use batching where possible
- All document paths must be per-user scoped
- All temporary data must have TTL cleanup

====================================================
COST DISCIPLINE

The AI must evaluate cost impact of every feature:

- What is the per-user cost at 100 users?
- What is the per-user cost at 10,000 users?
- What is the per-user cost at 5,000,000 users?
- Does cost grow linearly, logarithmically, or exponentially?
- Is there a cost ceiling per operation?

Features with exponential cost growth are REJECTED.

====================================================
GRACEFUL DEGRADATION REQUIREMENTS

Under excessive load, the system must:

- queue excess requests (not drop them)
- reduce polling frequency (not stop it)
- defer non-critical operations
- maintain safety-critical operations (risk engine, killswitch)
- communicate load status to users honestly
- NEVER disable safety systems to improve throughput

====================================================
FINAL DIRECTIVE

Scaling failures are NOT sudden.

They accumulate silently until they cascade.

The system must continuously monitor for:

- latency creep
- memory growth
- queue backup
- error rate increase
- lock contention
- cost acceleration

Prevention is ALWAYS cheaper than recovery.

SURVIVAL FIRST.
SCALING SECOND.
FEATURES THIRD.
