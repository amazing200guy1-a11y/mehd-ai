"""
Mehd AI — System Health Registry
=================================
Lightweight, in-memory health aggregation for operational visibility.

Design Rules (per doctrine):
  - ZERO Firestore writes
  - ZERO polling loops
  - ZERO external dependencies
  - Push-based: subsystems report their own health
  - asyncio.Lock for atomic mutation/snapshot reads
  - Bounded metrics (max 10 keys per subsystem)
  - Sovereign-only detailed access
"""

import asyncio
import logging
from datetime import datetime, timezone
from typing import Optional

logger = logging.getLogger("mehd.health")

# ── Health States ──────────────────────────────
# GREEN  = healthy, connected, synchronized
# YELLOW = degraded, reconnecting, delayed, partial outage
# RED    = paused, disconnected, execution blocked, critical failure

VALID_STATES = {"GREEN", "YELLOW", "RED"}

# Maximum metric keys per subsystem to prevent memory creep
MAX_METRICS_PER_SUBSYSTEM = 10


class SubsystemHealth:
    """Immutable snapshot of a single subsystem's health."""

    __slots__ = ("name", "state", "detail", "last_heartbeat", "metrics")

    def __init__(
        self,
        name: str,
        state: str = "RED",
        detail: str = "Awaiting first heartbeat",
        metrics: Optional[dict] = None,
    ):
        self.name = name
        self.state = state if state in VALID_STATES else "RED"
        self.detail = detail
        self.last_heartbeat = datetime.now(timezone.utc)
        self.metrics = metrics or {}

    def to_public_dict(self) -> dict:
        """Safe representation for the public /health endpoint.
        NEVER exposes detail text, queue depths, retry counters, or infrastructure topology."""
        return {
            "state": self.state,
            "last_heartbeat": self.last_heartbeat.isoformat(),
        }

    def to_ops_dict(self) -> dict:
        """Full representation for sovereign /ops/health endpoint only."""
        return {
            "state": self.state,
            "detail": self.detail,
            "last_heartbeat": self.last_heartbeat.isoformat(),
            "metrics": self.metrics,
        }


class SystemHealthRegistry:
    """
    Central health aggregation registry.

    Thread-safety: Uses asyncio.Lock for atomic report/snapshot operations.
    The lock is held ONLY during dict mutation and dict copy — never during
    subsystem loop execution.
    """

    def __init__(self):
        self._subsystems: dict[str, SubsystemHealth] = {}
        self._lock = asyncio.Lock()
        self._boot_time = datetime.now(timezone.utc)

    async def report(
        self,
        name: str,
        state: str,
        detail: str = "",
        metrics: Optional[dict] = None,
    ) -> None:
        """Called by each subsystem at the end of its loop cycle.
        ~1μs overhead — single dict assignment under lock."""
        if state not in VALID_STATES:
            logger.warning("Health report for '%s' has invalid state '%s', defaulting to RED", name, state)
            state = "RED"

        # Bound metrics to prevent memory creep
        safe_metrics = {}
        if metrics:
            for i, (k, v) in enumerate(metrics.items()):
                if i >= MAX_METRICS_PER_SUBSYSTEM:
                    break
                safe_metrics[k] = v

        async with self._lock:
            self._subsystems[name] = SubsystemHealth(
                name=name,
                state=state,
                detail=detail,
                metrics=safe_metrics,
            )

    async def snapshot(self, ops_level: bool = False) -> dict:
        """Returns an atomic copy of all subsystem health states.
        ops_level=True returns full metrics (sovereign only).
        ops_level=False returns safe public representation.
        
        SELF-CORRECTION FIX: aggregate_state is now computed INSIDE the same
        lock acquisition to prevent race conditions where the subsystem data
        and aggregate state become inconsistent."""
        async with self._lock:
            if ops_level:
                subsystems = {
                    name: health.to_ops_dict()
                    for name, health in self._subsystems.items()
                }
            else:
                subsystems = {
                    name: health.to_public_dict()
                    for name, health in self._subsystems.items()
                }
            # Compute aggregate INSIDE lock — prevents race with concurrent reports
            aggregate = self._compute_aggregate_locked()

        return {
            "aggregate_state": aggregate,
            "boot_time": self._boot_time.isoformat(),
            "subsystems": subsystems,
        }

    async def aggregate_state(self) -> str:
        """Returns the worst-case state across all subsystems.
        Acquires its own lock for standalone use (e.g. /health endpoint)."""
        async with self._lock:
            return self._compute_aggregate_locked()

    def _compute_aggregate_locked(self) -> str:
        """Internal: compute aggregate state. Caller MUST hold self._lock."""
        if not self._subsystems:
            return "GREEN"  # No subsystems registered yet = startup
        states = [h.state for h in self._subsystems.values()]
        if "RED" in states:
            return "RED"
        if "YELLOW" in states:
            return "YELLOW"
        return "GREEN"


# ── Singleton ──────────────────────────────────
health_registry = SystemHealthRegistry()
""" 
Description: Lightweight, in-memory health aggregation for operational visibility.
"""
