"""
Mehd AI — Post Mortem Agent (Self-Correction Layer)
===================================================
When a trade with high consensus (>75%) somehow loses money, this agent
wakes up. It investigates the market snapshot and the AI reasoning
to find the blind spot, then WRITES a new rule to the constitution
so the HardRiskKernel never makes that mistake again.

STORAGE NOTE (SELF-CRITIQUE-06):
  Rules are stored in FIRESTORE (collection: 'constitution', doc: 'rules'),
  NOT the local filesystem. Cloud containers have ephemeral filesystems that
  reset on every redeploy — storing rules in a local JSON file would silently
  wipe the entire constitution on every deployment.
  The local app_constitution.json is only used as a cold-start read cache.
"""

import json
import logging
import os
import threading
import uuid
import httpx
from datetime import datetime

logger = logging.getLogger("mehd.postmortem")

CONSTITUTION_FILE = os.path.join(os.path.dirname(__file__), "app_constitution.json")
PENDING_RULES_FILE = os.path.join(os.path.dirname(__file__), "pending_constitution_rules.json")

# Firestore collection / document identifiers for persistent storage
_FIRESTORE_COLLECTION = "constitution"
_LIVE_DOC = "live_rules"
_PENDING_DOC = "pending_rules"


async def _firestore_get(doc_id: str) -> dict:
    """Load a constitution document from Firestore. Returns empty dict on failure."""
    try:
        from storage import storage
        data = await storage.get(_FIRESTORE_COLLECTION, doc_id)
        return data or {}
    except Exception as e:
        logger.warning("[CONSTITUTION] Firestore read failed for %s: %s", doc_id, e)
        return {}


async def _firestore_set(doc_id: str, data: dict) -> None:
    """Persist a constitution document to Firestore atomically."""
    try:
        from storage import storage
        await storage.set(_FIRESTORE_COLLECTION, doc_id, data)
    except Exception as e:
        logger.error("[CONSTITUTION] Firestore write FAILED for %s: %s", doc_id, e)


class PostMortemAgent:
    # SECURITY: Maximum number of auto-generated rules to prevent unbounded growth
    MAX_AUTO_RULES = 50
    # SECURITY: Maximum length for rule descriptions (prevent token bombs)
    MAX_DESCRIPTION_LENGTH = 300

    def __init__(self):
        self._lock = threading.Lock()
        self._ensure_file_exists()

    def _ensure_file_exists(self):
        """Create local cache file if missing. Non-fatal if filesystem is read-only."""
        try:
            if not os.path.exists(CONSTITUTION_FILE):
                with open(CONSTITUTION_FILE, "w") as f:
                    json.dump({"rules": []}, f, indent=2)
        except OSError as e:
            logger.warning("[CONSTITUTION] Could not create local cache file (ephemeral filesystem?): %s", e)

    def _sanitize_text(self, text: str) -> str:
        """Remove control characters and cap length for safety."""
        import re
        clean = re.sub(r'[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]', '', str(text))
        return clean[:self.MAX_DESCRIPTION_LENGTH].strip()

    async def analyze_loss(self, symbol: str, direction: str, snapshot_dump: str, original_consensus: float):
        """
        In production, this queries GPT-5.4 with the full post-trade market data
        to deduce what went wrong. For now, it mocks the introspection and generates a rule.
        """
        logger.warning("[POST-MORTEM ACTIVATED] Investigating %.1f%% consensus loss on %s %s", original_consensus, symbol, direction)
        
        # SECURITY: Check current rule count before adding (prevent unbounded growth — ASI01)
        try:
            with open(CONSTITUTION_FILE, "r") as f:
                data = json.load(f)
            current_count = len(data.get("rules", []))
            if current_count >= self.MAX_AUTO_RULES:
                logger.warning("[POST-MORTEM] Max auto-rules reached (%d). Skipping rule generation.", self.MAX_AUTO_RULES)
                return {"id": "LIMIT_REACHED", "description": "Maximum auto-generated rules reached. Manual review required.", "action": "NONE"}
        except Exception as e:
            logger.warning("Failed to check current rule count: %s", e)
        
        # Simulate thinking
        rule_id = "rule_auto_%s" % uuid.uuid4().hex[:6]
        
        # SECURITY: Sanitize inputs that flow into the rule description
        safe_symbol = self._sanitize_text(symbol)
        safe_direction = self._sanitize_text(direction)
        
        # Simulated Structural Introspection (Replaces time-based overfitting)
        # If the trade was a BUY and lost, it might have been due to hidden sell pressure in the DOM.
        new_rule = {
            "id": rule_id,
            "name": f"Structural Veto ({safe_symbol})",
            "description": f"Autonomous VETO: Blocks {safe_direction} on {safe_symbol} during high volatility and hostile Order Book (DOM) imbalances, learned from the {datetime.utcnow().strftime('%Y-%m-%d')} anomaly.",
            "rule_type": "dynamic_veto",
            "condition_payload": {
                "symbol": safe_symbol,
                "direction": safe_direction,
                "max_spread_allowed": 3.5,
                # If BUYing, veto if DOM imbalance is strongly negative (hidden sellers)
                # If SELLing, veto if DOM imbalance is strongly positive (hidden buyers)
                "min_dom_imbalance": -0.5 if safe_direction == "BUY" else None,
                "max_dom_imbalance": 0.5 if safe_direction == "SELL" else None,
            },
            "status": "pending_review",  # SECURITY (APT-02): Rules are sandboxed until admin approval
        }
        
        await self._queue_pending_rule(new_rule)
        return new_rule

    async def _queue_pending_rule(self, rule: dict) -> None:
        """Queue a rule for admin review in Firestore instead of the live constitution.

        SECURITY (APT-02 + SELF-CRITIQUE-06): Autonomous rules are written to a
        SEPARATE Firestore document ('constitution/pending_rules'). The live Risk
        Kernel constitution ('constitution/live_rules') is untouched until an admin
        explicitly approves the rule. Rules survive container restarts and redeploys.
        """
        # Load current pending rules from Firestore
        data = await _firestore_get(_PENDING_DOC)
        pending = data.get("pending_rules", [])

        # SECURITY: Enforce max pending rules cap
        if len(pending) >= self.MAX_AUTO_RULES:
            logger.warning("[CONSTITUTION] Pending rule cap reached (%d). Not queuing.", self.MAX_AUTO_RULES)
            return

        pending.append(rule)
        await _firestore_set(_PENDING_DOC, {"pending_rules": pending})
        logger.info("[CONSTITUTION] Rule QUEUED for admin review: %s", rule["description"])

    async def approve_pending_rule(self, rule_id: str) -> dict | None:
        """Admin-only: Move a pending rule from the sandbox into the live constitution.

        Both the live constitution and pending queue are stored in Firestore,
        so this operation is durable across container restarts.
        """
        # Load pending from Firestore
        pending_data = await _firestore_get(_PENDING_DOC)
        pending = pending_data.get("pending_rules", [])

        # Find the rule
        target_rule = None
        remaining = [rule for rule in pending if rule.get("id") != rule_id]
        for rule in pending:
            if rule.get("id") == rule_id:
                target_rule = rule
                break

        if not target_rule:
            return None

        # Activate and append to live constitution in Firestore
        target_rule["status"] = "active"
        live_data = await _firestore_get(_LIVE_DOC)
        live_rules = live_data.get("rules", [])
        live_rules.append(target_rule)

        # Write both atomically (best-effort; Firestore is not multi-doc transactional here)
        await _firestore_set(_LIVE_DOC, {"rules": live_rules})
        await _firestore_set(_PENDING_DOC, {"pending_rules": remaining})

        logger.info("[CONSTITUTION APPROVED] Rule %s promoted to live: %s", rule_id, target_rule["description"])
        return target_rule

    async def get_pending_rules(self) -> list:
        """Return all pending rules awaiting admin review."""
        data = await _firestore_get(_PENDING_DOC)
        return data.get("pending_rules", [])

    async def reject_pending_rule(self, rule_id: str) -> bool:
        """Admin-only: Permanently discard a pending rule without activating it."""
        pending_data = await _firestore_get(_PENDING_DOC)
        pending = pending_data.get("pending_rules", [])
        remaining = [r for r in pending if r.get("id") != rule_id]
        if len(remaining) == len(pending):
            return False  # Rule not found
        await _firestore_set(_PENDING_DOC, {"pending_rules": remaining})
        logger.info("[CONSTITUTION] Rule %s REJECTED and discarded by admin.", rule_id)
        return True

    def _append_rule(self, rule: dict):
        """Direct append to live constitution. Only used by approve_pending_rule internally."""
        # Kept for backwards compatibility — but no longer called by analyze_loss.
        pass

post_mortem = PostMortemAgent()
