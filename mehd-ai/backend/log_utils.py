"""
Mehd AI — Secure Logging Utilities
====================================
COMPULSORY.md Rule 7: All failures must log with context.
SECURITY: UIDs must never appear in plain text in logs — use truncated
hashes to prevent PII leakage in log aggregators (CloudWatch, Stackdriver).

Usage:
    from log_utils import safe_uid
    logger.info("Trade executed for user %s", safe_uid(uid))
    # Output: "Trade executed for user u_a1b2c3d4"
"""

import hashlib


def safe_uid(uid: str) -> str:
    """Returns a truncated, non-reversible identifier for logging.
    
    Produces a consistent 8-char hash prefix so logs can be correlated
    across requests for the same user WITHOUT exposing the real Firebase UID.
    
    The 'u_' prefix makes it easy to grep for user identifiers in logs.
    """
    if not uid:
        return "u_unknown"
    h = hashlib.sha256(uid.encode()).hexdigest()[:8]
    return f"u_{h}"


def safe_email(email: str) -> str:
    """Masks an email for logging: 'user@example.com' -> 'u***@example.com'"""
    if not email or "@" not in email:
        return "***@***"
    local, domain = email.rsplit("@", 1)
    masked_local = local[0] + "***" if local else "***"
    return f"{masked_local}@{domain}"
