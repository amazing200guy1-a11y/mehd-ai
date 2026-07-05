"""
Mehd AI — Intent Capsule System (Agentic Security Layer)
=========================================================
OWASP ASI01 (Goal Hijacking) + ASI02 (Excessive Agency) Defense

An "Intent Capsule" is a cryptographically signed wrapper around
every AI agent's vote. Once a vote is cast, its core fields
(direction, confidence, model_name) are FROZEN and tamper-evident.

WHY THIS MATTERS:
Without this, a compromised agent or a prompt injection attack
could modify another agent's vote after it's been cast but before
the consensus is tallied. In a financial system, that means an
attacker could flip a SELL to a BUY by injecting into the
Chairman's synthesis prompt.

The capsule uses HMAC-SHA256 with a server-side secret. Even if
an attacker controls an agent's output, they cannot forge a valid
signature for a different vote because they don't have the secret.

Think of it like a wax seal on a letter — you can read it, but
if someone opens and re-seals it, you'll know it was tampered with.
"""

from __future__ import annotations

import hashlib
import hmac
import json
import os
import time
import logging
from dataclasses import dataclass

logger = logging.getLogger("mehd.intent_capsule")

# Server-side secret for HMAC signing — never exposed to agents
# In production, this comes from a secrets vault, not .env
_CAPSULE_SECRET = os.getenv("CAPSULE_SIGNING_SECRET", "mehd-ai-default-capsule-key-CHANGE-IN-PROD")

# Maximum age (seconds) before a capsule is considered stale
CAPSULE_MAX_AGE_SECONDS = 120  # 2 minutes — votes older than this are rejected


@dataclass(frozen=True)
class IntentCapsule:
    """
    Immutable, signed wrapper around an AI agent's vote.
    Once created, the direction, confidence, and model_name
    cannot be changed without invalidating the signature.
    """
    model_name: str
    direction: str          # BUY | SELL | HOLD
    confidence: float       # 0.0 — 100.0 (already sanitized)
    reasoning: str          # Sanitized reasoning text
    timestamp: float        # Unix epoch when the vote was cast
    signature: str          # HMAC-SHA256 digest of the core fields

    def is_valid(self) -> bool:
        """Verify the capsule hasn't been tampered with."""
        expected = _compute_signature(
            self.model_name,
            self.direction,
            self.confidence,
            self.timestamp,
        )
        return hmac.compare_digest(self.signature, expected)

    def is_fresh(self) -> bool:
        """Reject stale votes — prevents replay attacks."""
        age = time.time() - self.timestamp
        return 0 <= age <= CAPSULE_MAX_AGE_SECONDS

    def verify(self) -> tuple[bool, str]:
        """
        Full verification: signature + freshness.
        Returns (is_valid, reason).
        """
        if not self.is_valid():
            return False, "TAMPERED: Signature mismatch — vote was modified after signing"
        if not self.is_fresh():
            age = time.time() - self.timestamp
            return False, "STALE: Vote is %.1fs old (max %ds)" % (age, CAPSULE_MAX_AGE_SECONDS)
        return True, "VERIFIED"


def sign_vote(
    model_name: str,
    direction: str,
    confidence: float,
    reasoning: str,
) -> IntentCapsule:
    """
    Creates a signed IntentCapsule from raw vote data.
    Called immediately after parsing each agent's LLM response.
    """
    ts = time.time()
    sig = _compute_signature(model_name, direction, confidence, ts)

    capsule = IntentCapsule(
        model_name=model_name,
        direction=direction,
        confidence=confidence,
        reasoning=reasoning,
        timestamp=ts,
        signature=sig,
    )

    logger.debug(
        "IntentCapsule signed: %s → %s (%.1f%%) sig=%s",
        model_name, direction, confidence, sig[:12] + "..."
    )
    return capsule


def verify_all_capsules(capsules: list[IntentCapsule]) -> tuple[bool, list[str]]:
    """
    Batch-verify all capsules before consensus tally.
    Returns (all_valid, list_of_failures).
    """
    failures: list[str] = []

    for capsule in capsules:
        is_ok, reason = capsule.verify()
        if not is_ok:
            failure_msg = "[%s] %s" % (capsule.model_name, reason)
            failures.append(failure_msg)
            logger.critical("INTENT CAPSULE BREACH: %s", failure_msg)

    if failures:
        logger.critical(
            "CONSENSUS BLOCKED: %d/%d capsules failed verification",
            len(failures), len(capsules)
        )
        return False, failures

    logger.info("All %d Intent Capsules verified — consensus is tamper-free", len(capsules))
    return True, []


def _compute_signature(
    model_name: str,
    direction: str,
    confidence: float,
    timestamp: float,
) -> str:
    """
    HMAC-SHA256 signature over the immutable vote fields.
    Uses a server-side secret that no agent has access to.
    """
    payload = json.dumps({
        "m": model_name,
        "d": direction,
        "c": round(confidence, 2),
        "t": round(timestamp, 6),
    }, sort_keys=True, separators=(",", ":"))

    return hmac.new(
        _CAPSULE_SECRET.encode("utf-8"),
        payload.encode("utf-8"),
        hashlib.sha256,
    ).hexdigest()
