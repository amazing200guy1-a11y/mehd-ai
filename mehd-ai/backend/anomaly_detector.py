"""
Mehd AI — Anomaly Detector (Agentic Behavior Monitor)
=======================================================
OWASP ASI05 (Insufficient Monitoring) Defense

This module monitors the AI agent system for suspicious behavioral
patterns that could indicate prompt injection, goal hijacking,
or a malfunctioning agent. It runs passively alongside every
consensus decision and raises alerts when something looks wrong.

WHAT IT DETECTS:
1. Confidence Spikes — An agent suddenly reports 99%+ confidence
   when it was averaging 65%. Could mean prompt injection.
2. Directional Lock — An agent votes the same direction 20+ times
   in a row. Healthy agents should have variety.
3. Rapid-Fire Consensus — 10+ analyses in under 60 seconds.
   Could mean an automated attack.
4. Reasoning Repetition — Same reasoning text used verbatim across
   multiple analyses. Indicates a stuck or hijacked model.
5. Unanimous Streak — All agents agree on everything for too long.
   In real markets, this almost never happens.

Think of this like a security camera for your AI workforce — you
don't watch it constantly, but when something goes wrong, you can
see exactly what happened and when it started.
"""

from __future__ import annotations

import logging
import time
from collections import defaultdict, deque
from dataclasses import dataclass, field
from typing import Optional

logger = logging.getLogger("mehd.anomaly_detector")

# ──────────────────────────────────────────────
#  Configuration Thresholds
# ──────────────────────────────────────────────

# Alert if any agent reports confidence above this
CONFIDENCE_SPIKE_THRESHOLD = 98.0

# Alert if an agent votes the same direction this many times in a row
DIRECTIONAL_LOCK_THRESHOLD = 20

# Alert if this many analyses happen within the time window
RAPID_FIRE_COUNT = 10
RAPID_FIRE_WINDOW_SECONDS = 60

# Alert if the same reasoning appears this many times
REASONING_REPETITION_THRESHOLD = 5

# Alert if all agents are unanimous this many times in a row
UNANIMOUS_STREAK_THRESHOLD = 10

# Maximum history to keep per agent (prevent memory leak)
MAX_HISTORY_PER_AGENT = 200


@dataclass
class AnomalyAlert:
    """An anomaly event that should be logged and potentially displayed."""
    alert_type: str        # e.g. CONFIDENCE_SPIKE, DIRECTIONAL_LOCK
    severity: str          # LOW, MEDIUM, HIGH, CRITICAL
    agent_name: str        # Which agent triggered it (or "SYSTEM" for global)
    message: str           # Human-readable description
    timestamp: float       # When it was detected
    metadata: dict = field(default_factory=dict)  # Extra context


class AnomalyDetector:
    """
    Stateful monitor that tracks agent behavior over time
    and raises alerts when anomalous patterns are detected.
    """

    def __init__(self) -> None:
        # Per-agent direction history: agent_name → deque of recent directions
        self._direction_history: dict[str, deque] = defaultdict(lambda: deque(maxlen=MAX_HISTORY_PER_AGENT))

        # Per-agent confidence history: agent_name → deque of recent confidences
        self._confidence_history: dict[str, deque] = defaultdict(lambda: deque(maxlen=MAX_HISTORY_PER_AGENT))

        # Per-agent reasoning history: agent_name → deque of recent reasoning strings
        self._reasoning_history: dict[str, deque] = defaultdict(lambda: deque(maxlen=MAX_HISTORY_PER_AGENT))

        # Global analysis timestamps (for rapid-fire detection)
        self._analysis_timestamps: deque = deque(maxlen=100)

        # Unanimous streak counter
        self._unanimous_streak: int = 0

        # All alerts raised (capped)
        self._alerts: deque[AnomalyAlert] = deque(maxlen=500)

        logger.info("AnomalyDetector initialized — monitoring agent behavior")

    def check_consensus(self, votes: list, symbol: str) -> list[AnomalyAlert]:
        """
        Run all anomaly checks on a set of votes from one consensus round.
        Returns a list of alerts (empty if everything looks normal).

        Each vote should have: model_name, direction (str/enum), confidence, reasoning
        """
        alerts: list[AnomalyAlert] = []
        now = time.time()

        # Record the analysis timestamp
        self._analysis_timestamps.append(now)

        for vote in votes:
            agent = getattr(vote, 'model_name', str(vote))
            direction = str(getattr(vote, 'direction', 'UNKNOWN'))
            if hasattr(direction, 'value'):
                direction = direction.value
            confidence = float(getattr(vote, 'confidence', 0.0))
            reasoning = str(getattr(vote, 'reasoning', ''))

            # Record history
            self._direction_history[agent].append(direction)
            self._confidence_history[agent].append(confidence)
            self._reasoning_history[agent].append(reasoning)

            # CHECK 1: Confidence Spike
            if confidence >= CONFIDENCE_SPIKE_THRESHOLD:
                hist = list(self._confidence_history[agent])
                if len(hist) >= 3:
                    avg_recent = sum(hist[-10:]) / len(hist[-10:])
                    if confidence > avg_recent * 1.3:  # 30% above recent average
                        alert = AnomalyAlert(
                            alert_type="CONFIDENCE_SPIKE",
                            severity="HIGH",
                            agent_name=agent,
                            message="%s confidence spiked to %.1f%% (recent avg: %.1f%%) on %s — possible prompt injection" % (agent, confidence, avg_recent, symbol),
                            timestamp=now,
                            metadata={"confidence": confidence, "avg": avg_recent, "symbol": symbol},
                        )
                        alerts.append(alert)

            # CHECK 2: Directional Lock
            dir_hist = list(self._direction_history[agent])
            if len(dir_hist) >= DIRECTIONAL_LOCK_THRESHOLD:
                last_n = dir_hist[-DIRECTIONAL_LOCK_THRESHOLD:]
                if len(set(last_n)) == 1 and last_n[0] != "HOLD":
                    alert = AnomalyAlert(
                        alert_type="DIRECTIONAL_LOCK",
                        severity="MEDIUM",
                        agent_name=agent,
                        message="%s has voted %s for %d consecutive analyses — possible model fixation" % (agent, last_n[0], DIRECTIONAL_LOCK_THRESHOLD),
                        timestamp=now,
                        metadata={"locked_direction": last_n[0], "streak": DIRECTIONAL_LOCK_THRESHOLD},
                    )
                    alerts.append(alert)

            # CHECK 3: Reasoning Repetition
            reason_hist = list(self._reasoning_history[agent])
            if len(reason_hist) >= REASONING_REPETITION_THRESHOLD:
                last_n_reasons = reason_hist[-REASONING_REPETITION_THRESHOLD:]
                if len(set(last_n_reasons)) == 1:
                    alert = AnomalyAlert(
                        alert_type="REASONING_REPETITION",
                        severity="HIGH",
                        agent_name=agent,
                        message="%s gave identical reasoning %d times in a row — possible hijacked or frozen model" % (agent, REASONING_REPETITION_THRESHOLD),
                        timestamp=now,
                        metadata={"repeated_text": reasoning[:100]},
                    )
                    alerts.append(alert)

        # CHECK 4: Rapid-Fire Detection (global)
        recent_analyses = [t for t in self._analysis_timestamps if (now - t) < RAPID_FIRE_WINDOW_SECONDS]
        if len(recent_analyses) >= RAPID_FIRE_COUNT:
            alert = AnomalyAlert(
                alert_type="RAPID_FIRE",
                severity="CRITICAL",
                agent_name="SYSTEM",
                message="%d analyses in %d seconds — possible automated attack or runaway loop" % (len(recent_analyses), RAPID_FIRE_WINDOW_SECONDS),
                timestamp=now,
                metadata={"count": len(recent_analyses), "window": RAPID_FIRE_WINDOW_SECONDS},
            )
            alerts.append(alert)

        # CHECK 5: Unanimous Streak
        if votes:
            directions = set()
            for v in votes:
                d = getattr(v, 'direction', 'UNKNOWN')
                if hasattr(d, 'value'):
                    d = d.value
                directions.add(str(d))

            if len(directions) == 1:
                self._unanimous_streak += 1
            else:
                self._unanimous_streak = 0

            if self._unanimous_streak >= UNANIMOUS_STREAK_THRESHOLD:
                alert = AnomalyAlert(
                    alert_type="UNANIMOUS_STREAK",
                    severity="HIGH",
                    agent_name="SYSTEM",
                    message="All agents agreed unanimously for %d consecutive analyses — statistically improbable" % self._unanimous_streak,
                    timestamp=now,
                    metadata={"streak": self._unanimous_streak},
                )
                alerts.append(alert)

        # Store and log alerts
        for alert in alerts:
            self._alerts.append(alert)
            if alert.severity == "CRITICAL":
                logger.critical("[ANOMALY] %s: %s", alert.alert_type, alert.message)
            elif alert.severity == "HIGH":
                logger.warning("[ANOMALY] %s: %s", alert.alert_type, alert.message)
            else:
                logger.info("[ANOMALY] %s: %s", alert.alert_type, alert.message)

        return alerts

    def get_recent_alerts(self, count: int = 50) -> list[dict]:
        """Returns recent alerts as dicts for the API."""
        return [
            {
                "type": a.alert_type,
                "severity": a.severity,
                "agent": a.agent_name,
                "message": a.message,
                "timestamp": a.timestamp,
            }
            for a in list(self._alerts)[-count:]
        ]

    def get_status(self) -> dict:
        """Summary for the /health endpoint."""
        total_alerts = len(self._alerts)
        critical_count = sum(1 for a in self._alerts if a.severity == "CRITICAL")
        high_count = sum(1 for a in self._alerts if a.severity == "HIGH")
        return {
            "total_alerts": total_alerts,
            "critical_alerts": critical_count,
            "high_alerts": high_count,
            "unanimous_streak": self._unanimous_streak,
            "agents_tracked": len(self._direction_history),
        }


# Global singleton
anomaly_detector = AnomalyDetector()
