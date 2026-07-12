"""
Mehd AI — Payment Routes (Paddle + Paystack Integration)
=========================================================
DUAL GATEWAY ARCHITECTURE:
  - Paddle   → Global: US, Europe, Asia, LatAm. Cards, PayPal, Apple/Google Pay.
               Acts as Merchant of Record — Paddle handles all global VAT/tax.
  - Paystack → Africa: Nigeria, South Africa, Ghana, Kenya.
               Local bank transfer, USSD, mobile money, Verve cards.

Why no Stripe? We are not using Apple/Google IAP, so we are free to process
payments via our website. Paddle and Paystack cover every trader globally with
zero tax compliance burden on us.

Endpoints:
    POST /payments/paddle-webhook    → Paddle subscription events
    POST /payments/paystack-webhook  → Paystack subscription events
    GET  /payments/status            → Current user's subscription status
    GET  /payments/portal            → Billing management URL for user
    GET  /payments/tiers             → Public pricing tiers

Security:
    - Paddle: HMAC-SHA256 signature verification (Paddle-Signature header)
    - Paystack: HMAC-SHA512 signature verification (x-paystack-signature header)
    - Server-side tier enforcement (client can NEVER set its own tier)
    - All tier changes logged to audit trail
    - Idempotency: processed event IDs tracked in memory + persistent storage
"""

from __future__ import annotations

import hashlib
import hmac
import logging
import os
import re as _re
import time
from collections import deque
from datetime import datetime, timezone

from fastapi import APIRouter, HTTPException, Request, Depends
from pydantic import BaseModel, Field
from slowapi import Limiter

from auth import get_current_user, get_real_ip, get_uid_rate_key

logger = logging.getLogger("mehd.routes.payments")
router = APIRouter(prefix="/payments", tags=["Payments"])
limiter = Limiter(key_func=get_uid_rate_key)

# ──────────────────────────────────────────────
#  Configuration — The Battery Slot
# ──────────────────────────────────────────────

# Paddle v2
PADDLE_WEBHOOK_SECRET = os.getenv("PADDLE_WEBHOOK_SECRET", "")

# Paddle Price IDs → Tier map (set in .env)
PADDLE_PRICE_IDS = {
    "core":          os.getenv("PADDLE_PRICE_CORE", ""),
    "precision":     os.getenv("PADDLE_PRICE_PRECISION", ""),
    "institutional": os.getenv("PADDLE_PRICE_INSTITUTIONAL", ""),
}
PADDLE_TO_TIER: dict[str, str] = {}  # Built on startup

# Paystack
PAYSTACK_SECRET_KEY = os.getenv("PAYSTACK_SECRET_KEY", "")

# Paystack Plan Codes → Tier map (set in .env)
PAYSTACK_PLAN_CODES = {
    "core":          os.getenv("PAYSTACK_PLAN_CORE", ""),
    "precision":     os.getenv("PAYSTACK_PLAN_PRECISION", ""),
    "institutional": os.getenv("PAYSTACK_PLAN_INSTITUTIONAL", ""),
}
PAYSTACK_TO_TIER: dict[str, str] = {}  # Built on startup


def _build_lookup_maps() -> None:
    global PADDLE_TO_TIER, PAYSTACK_TO_TIER
    PADDLE_TO_TIER    = {v: k for k, v in PADDLE_PRICE_IDS.items() if v}
    PAYSTACK_TO_TIER  = {v: k for k, v in PAYSTACK_PLAN_CODES.items() if v}

_build_lookup_maps()

# Webhook idempotency — tracks processed event IDs (L1 in-memory, L2 persistent)
_processed_event_ids: deque[str] = deque(maxlen=10_000)

# Free Trial
FREE_TRIAL_DAYS = 3
FREE_TRIAL_TIER = "institutional"

# Server-controlled redirect URLs — NEVER accept from client
PRICING_URL     = os.getenv("PRICING_URL", "https://mehdai.com/#pricing")
SUCCESS_URL     = os.getenv("CHECKOUT_SUCCESS_URL", "https://mehdai.com/success.html")

# ──────────────────────────────────────────────
#  Tier Configuration (Single Source of Truth)
# ──────────────────────────────────────────────

TIER_CONFIG = {
    "observer": {
        "display_name": "Observer Mode",
        "analyses_per_week": 1,
        "analyses_per_day": 0,
        "sniper_access": True,
        "autopilot_mode": "assisted",
        "risk_engine_protection": True,
        "institutional_tools": False,
        "morning_briefing": False,
        "missed_trade_recap": False,
        "advanced_analytics": False,
        "auto_charting": False,
        "price_monthly": 0,
    },
    "core": {
        "display_name": "Core Trader",
        "analyses_per_week": 999,
        "analyses_per_day": 10,
        "sniper_access": True,
        "autopilot_mode": "assisted",
        "risk_engine_protection": True,
        "institutional_tools": False,
        "morning_briefing": True,
        "missed_trade_recap": True,
        "advanced_analytics": False,
        "auto_charting": False,
        "price_monthly": 29.99,
    },
    "precision": {
        "display_name": "Precision Trader",
        "analyses_per_week": 999,
        "analyses_per_day": 50,
        "sniper_access": True,
        "autopilot_mode": "full",
        "risk_engine_protection": True,
        "institutional_tools": True,
        "morning_briefing": True,
        "missed_trade_recap": True,
        "advanced_analytics": True,
        "auto_charting": True,
        "price_monthly": 59.99,
    },
    "institutional": {
        "display_name": "Institutional",
        "analyses_per_week": 999,
        "analyses_per_day": 999,
        "sniper_access": True,
        "autopilot_mode": "full",
        "risk_engine_protection": True,
        "institutional_tools": True,
        "morning_briefing": True,
        "missed_trade_recap": True,
        "advanced_analytics": True,
        "auto_charting": True,
        "price_monthly": 99.99,
    },
}

_LEGACY_TIER_ALIASES = {
    "scout": "observer",
    "guardian": "core",
    "operative": "institutional",
}

def get_tier_config(tier_name: str) -> dict:
    resolved = _LEGACY_TIER_ALIASES.get(tier_name, tier_name)
    return TIER_CONFIG.get(resolved, TIER_CONFIG["observer"])


# ──────────────────────────────────────────────
#  In-Memory Caches
# ──────────────────────────────────────────────

_user_tiers: dict[str, str] = {}
# uid → billing portal URLs (provided by Paddle in subscription webhooks)
_user_portal_urls: dict[str, dict[str, str]] = {}
# Paystack: email → uid (for webhook routing)
_paystack_email_to_uid: dict[str, str] = {}

from cachetools import TTLCache
_async_tier_cache: TTLCache = TTLCache(maxsize=10_000, ttl=300)


def get_user_tier(uid: str) -> str:
    return _user_tiers.get(uid, "observer")


def set_user_tier(uid: str, tier: str, portal_urls: dict | None = None) -> None:
    old_tier = _user_tiers.get(uid, "observer")
    _user_tiers[uid] = tier
    _async_tier_cache[uid] = tier
    if portal_urls:
        _user_portal_urls[uid] = portal_urls
    logger.info("TIER CHANGE: User %s: %s → %s", uid, old_tier, tier)
    try:
        import asyncio
        from storage import storage
        asyncio.create_task(storage.set("user_tiers", uid, {
            "tier": tier,
            "updated_at": datetime.now(timezone.utc).isoformat(),
            "previous_tier": old_tier,
            "portal_urls": portal_urls or {},
        }))
    except Exception as e:
        logger.warning("Could not persist tier change: %s", e)


async def rebuild_tier_caches() -> None:
    """Rebuild all in-memory caches from persistent storage on startup."""
    from storage import storage
    rebuilt = 0
    try:
        tier_keys = await storage.list_keys("user_tiers")
        for uid in tier_keys:
            data = await storage.get("user_tiers", uid)
            if data and "tier" in data:
                _user_tiers[uid] = data["tier"]
                if "portal_urls" in data and data["portal_urls"]:
                    _user_portal_urls[uid] = data["portal_urls"]
                rebuilt += 1
    except Exception as e:
        logger.warning("Could not rebuild tier cache: %s", e)
    logger.info("✓ Tier caches rebuilt: %d tiers loaded from storage", rebuilt)


async def get_user_tier_async(uid: str) -> str:
    """Authoritative async tier lookup — checks persistent storage on cache miss."""
    cached_ttl = _async_tier_cache.get(uid)
    if cached_ttl:
        return cached_ttl
    cached = _user_tiers.get(uid)
    if cached and cached != "observer":
        _async_tier_cache[uid] = cached
        return cached
    try:
        from storage import storage
        tier_data = await storage.get("user_tiers", uid)
        if tier_data and "tier" in tier_data and tier_data["tier"] != "observer":
            tier_name = tier_data["tier"]
            _user_tiers[uid] = tier_name
            _async_tier_cache[uid] = tier_name
            return tier_name
    except Exception as e:
        logger.warning("Persistent tier lookup failed for %s: %s", uid, e)
    trial_info = await _get_trial_info(uid)
    if trial_info and trial_info.get("days_remaining", 0) > 0:
        _async_tier_cache[uid] = FREE_TRIAL_TIER
        return FREE_TRIAL_TIER
    _async_tier_cache[uid] = "observer"
    return "observer"


# ──────────────────────────────────────────────
#  Signature Verification Utilities
# ──────────────────────────────────────────────

def _verify_paddle_signature(payload: bytes, signature_header: str) -> bool:
    """
    Paddle v2 webhook signature verification.
    Header format: ts=<timestamp>;h1=<hmac_sha256_hex>
    Signed string: '<timestamp>:<raw_body>'
    """
    if not PADDLE_WEBHOOK_SECRET:
        logger.critical("PADDLE_WEBHOOK_SECRET is not set — bouncing webhook")
        return False
    try:
        parts = dict(item.split("=", 1) for item in signature_header.split(";"))
        ts = parts.get("ts", "")
        h1 = parts.get("h1", "")
        if not ts or not h1:
            return False
        # Replay attack guard: reject events older than 5 minutes
        if abs(time.time() - int(ts)) > 300:
            logger.warning("PADDLE WEBHOOK: Replay attack detected — timestamp %s", ts)
            return False
        signed_payload = f"{ts}:{payload.decode('utf-8')}"
        expected = hmac.new(
            PADDLE_WEBHOOK_SECRET.encode("utf-8"),
            signed_payload.encode("utf-8"),
            hashlib.sha256,
        ).hexdigest()
        return hmac.compare_digest(expected, h1)
    except Exception as e:
        logger.error("Paddle signature verification error: %s", e)
        return False


def _verify_paystack_signature(payload: bytes, signature_header: str) -> bool:
    """
    Paystack webhook signature verification.
    Header: x-paystack-signature = HMAC-SHA512(raw_body, secret_key)
    """
    if not PAYSTACK_SECRET_KEY:
        logger.critical("PAYSTACK_SECRET_KEY is not set — bouncing webhook")
        return False
    try:
        expected = hmac.new(
            PAYSTACK_SECRET_KEY.encode("utf-8"),
            payload,
            hashlib.sha512,
        ).hexdigest()
        return hmac.compare_digest(expected, signature_header)
    except Exception as e:
        logger.error("Paystack signature verification error: %s", e)
        return False


# ──────────────────────────────────────────────
#  Idempotency Guard
# ──────────────────────────────────────────────

async def _is_already_processed(event_id: str) -> bool:
    """Returns True if the event has already been processed."""
    if event_id in _processed_event_ids:
        return True
    from storage import storage
    if await storage.get("webhook_events", event_id):
        _processed_event_ids.append(event_id)
        return True
    return False


async def _mark_processed(event_id: str, event_type: str) -> None:
    _processed_event_ids.append(event_id)
    from storage import storage
    await storage.set("webhook_events", event_id, {
        "processed_at": datetime.now(timezone.utc).isoformat(),
        "event_type": event_type,
    })


# ──────────────────────────────────────────────
#  Paddle Webhook Handler
# ──────────────────────────────────────────────

@router.post("/paddle-webhook", summary="Paddle webhook handler", include_in_schema=False)
@limiter.limit("100/minute")
async def paddle_webhook(request: Request):
    """
    Handles Paddle v2 subscription events:
    - subscription.created  → new subscription, grant tier
    - subscription.updated  → plan/status change (grant or revoke)
    - subscription.canceled → cancel, downgrade to observer
    - transaction.completed → (optional) one-time purchase confirmation
    """
    payload = await request.body()
    sig_header = request.headers.get("Paddle-Signature", "")

    if not _verify_paddle_signature(payload, sig_header):
        logger.critical("PADDLE WEBHOOK: Invalid signature — possible tampering")
        raise HTTPException(status_code=400, detail="Invalid webhook signature")

    import json
    try:
        event = json.loads(payload)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid JSON payload")

    event_id   = event.get("notification_id", "")
    event_type = event.get("event_type", "")
    data       = event.get("data", {})

    logger.info("PADDLE WEBHOOK: %s (id: %s)", event_type, event_id)

    if event_id and await _is_already_processed(event_id):
        return {"status": "already_processed"}

    if event_id:
        await _mark_processed(event_id, event_type)

    # ── Extract UID from custom_data (we embed uid when creating checkout) ──
    custom_data = data.get("custom_data") or {}
    uid = custom_data.get("mehd_uid", "")

    if not uid:
        logger.warning("PADDLE WEBHOOK: No mehd_uid in custom_data for event %s", event_type)
        return {"status": "no_uid"}

    # ── Extract portal/billing management URLs from subscription data ──
    management_urls = data.get("management_urls") or {}
    portal_urls = {
        "update_payment_method": management_urls.get("update_payment_method", PRICING_URL),
        "cancel": management_urls.get("cancel", PRICING_URL),
    }

    if event_type in ("subscription.created", "subscription.updated"):
        status = data.get("status", "")
        if status in ("active", "trialing", "past_due"):
            # Find tier from price ID
            items = data.get("items") or []
            for item in items:
                price_id = (item.get("price") or {}).get("id", "")
                tier = PADDLE_TO_TIER.get(price_id)
                if tier:
                    set_user_tier(uid, tier, portal_urls)
                    logger.info("PADDLE: User %s → %s (status: %s)", uid, tier, status)
                    break
        elif status in ("canceled", "paused"):
            await _downgrade_user(uid, "paddle subscription paused/canceled")

    elif event_type == "subscription.canceled":
        await _downgrade_user(uid, "paddle subscription canceled")

    return {"status": "ok"}


# ──────────────────────────────────────────────
#  Paystack Webhook Handler
# ──────────────────────────────────────────────

@router.post("/paystack-webhook", summary="Paystack webhook handler", include_in_schema=False)
@limiter.limit("100/minute")
async def paystack_webhook(request: Request):
    """
    Handles Paystack subscription events:
    - subscription.create   → new subscription, grant tier
    - subscription.disable  → cancellation, downgrade to observer
    - invoice.payment_failed → warn, do not punish immediately
    """
    payload = await request.body()
    sig_header = request.headers.get("x-paystack-signature", "")

    if not _verify_paystack_signature(payload, sig_header):
        logger.critical("PAYSTACK WEBHOOK: Invalid signature — possible tampering")
        raise HTTPException(status_code=400, detail="Invalid webhook signature")

    import json
    try:
        event = json.loads(payload)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid JSON payload")

    event_id   = event.get("id", str(int(time.time() * 1000)))  # Paystack uses numeric IDs
    event_type = event.get("event", "")
    data       = event.get("data", {})

    logger.info("PAYSTACK WEBHOOK: %s (id: %s)", event_type, event_id)

    if str(event_id) and await _is_already_processed(str(event_id)):
        return {"status": "already_processed"}

    if event_id:
        await _mark_processed(str(event_id), event_type)

    if event_type == "subscription.create":
        # Paystack embeds customer email and plan code
        customer = data.get("customer") or {}
        email    = customer.get("email", "")
        plan     = data.get("plan") or {}
        plan_code = plan.get("plan_code", "")

        tier = PAYSTACK_TO_TIER.get(plan_code)
        if not tier:
            logger.warning("PAYSTACK: Unknown plan_code %s — cannot map to tier", plan_code)
            return {"status": "unknown_plan"}

        # Resolve UID from email via Firebase
        uid = await _uid_from_email(email)
        if not uid:
            logger.warning("PAYSTACK: No Firebase user found for email %s", email)
            return {"status": "user_not_found"}

        # Cache the email → uid mapping
        _paystack_email_to_uid[email] = uid

        # Paystack does not provide self-service portal URLs.
        # We direct users to the website billing section.
        portal_urls = {
            "update_payment_method": PRICING_URL,
            "cancel": PRICING_URL,
        }
        set_user_tier(uid, tier, portal_urls)
        logger.info("PAYSTACK: User %s (%s) → %s", uid, email, tier)

    elif event_type == "subscription.disable":
        customer  = data.get("customer") or {}
        email     = customer.get("email", "")
        uid = _paystack_email_to_uid.get(email) or await _uid_from_email(email)
        if uid:
            await _downgrade_user(uid, "paystack subscription disabled")

    elif event_type == "invoice.payment_failed":
        customer = data.get("customer") or {}
        email    = customer.get("email", "")
        uid = _paystack_email_to_uid.get(email) or await _uid_from_email(email)
        if uid:
            logger.warning("PAYSTACK PAYMENT FAILED: User %s (%s) — Paystack will retry", uid, email)

    return {"status": "ok"}


# ──────────────────────────────────────────────
#  Helper: Downgrade User
# ──────────────────────────────────────────────

async def _downgrade_user(uid: str, reason: str) -> None:
    """Downgrade a user to observer, unless they have an active free trial."""
    trial_info = await _get_trial_info(uid)
    if trial_info and trial_info.get("days_remaining", 0) > 0:
        set_user_tier(uid, FREE_TRIAL_TIER)
        logger.info("DOWNGRADE (%s): User %s fell back to active trial tier", reason, uid)
    else:
        set_user_tier(uid, "observer")
        logger.info("DOWNGRADE (%s): User %s → observer", reason, uid)


# ──────────────────────────────────────────────
#  Helper: Email → Firebase UID
# ──────────────────────────────────────────────

async def _uid_from_email(email: str) -> str | None:
    """Resolve a Firebase UID from an email address."""
    if not email:
        return None
    try:
        from firebase_admin import auth as fb_auth
        user = fb_auth.get_user_by_email(email)
        return user.uid
    except Exception as e:
        logger.warning("Could not resolve UID from email %s: %s", email, e)
        return None


# ──────────────────────────────────────────────
#  Free Trial System
# ──────────────────────────────────────────────

async def _get_trial_info(uid: str) -> dict | None:
    """Get trial status for a user. Returns None if never activated."""
    try:
        from storage import storage
        trial_data = await storage.get("user_trials", uid)
        if not trial_data or "activated_at" not in trial_data:
            return None
        activated_at = datetime.fromisoformat(trial_data["activated_at"])
        now = datetime.now(timezone.utc)
        elapsed = (now - activated_at).days
        days_remaining = max(0, FREE_TRIAL_DAYS - elapsed)
        return {
            "activated_at": trial_data["activated_at"],
            "days_remaining": days_remaining,
            "is_active": days_remaining > 0,
            "trial_tier": FREE_TRIAL_TIER,
        }
    except Exception as e:
        logger.warning("Trial lookup failed for %s: %s", uid, e)
        return None


async def activate_trial(uid: str, normalized_phone: str, ip_key: str) -> dict:
    """Activate the free trial for a new user (idempotent)."""
    from storage import storage
    existing = await _get_trial_info(uid)
    if existing:
        return existing
    now = datetime.now(timezone.utc)
    trial_data = {
        "activated_at": now.isoformat(),
        "trial_tier": FREE_TRIAL_TIER,
        "trial_days": FREE_TRIAL_DAYS,
    }
    await storage.set("user_trials", uid, trial_data)
    # Burn the normalized phone number so all formatting variants are blocked
    await storage.set("phone_trials", normalized_phone, {"uid": uid, "activated_at": now.isoformat()})
    logger.info("🔥 TRIAL ACTIVATED: User %s → %d days of %s access", uid, FREE_TRIAL_DAYS, FREE_TRIAL_TIER)
    return {
        "activated_at": now.isoformat(),
        "days_remaining": FREE_TRIAL_DAYS,
        "is_active": True,
        "trial_tier": FREE_TRIAL_TIER,
    }


# ──────────────────────────────────────────────
#  Activate Trial Endpoint
# ──────────────────────────────────────────────

@router.post("/activate-trial", summary="Activate the free Institutional trial")
async def activate_trial_endpoint(request: Request, uid: str = Depends(get_current_user)):
    """
    Activates the 3-day free Institutional trial for a new user.
    Requires a verified phone number to prevent infinite trial exploits.
    """
    client_ip = get_real_ip(request)
    from storage import storage
    from firebase_admin import auth as fb_auth

    user_record = fb_auth.get_user(uid)
    phone_number = getattr(user_record, "phone_number", None)

    if not phone_number:
        raise HTTPException(
            status_code=403,
            detail="A verified phone number is required to activate the free trial. Please link your phone number in Settings.",
        )

    normalized_phone = _re.sub(r"\D", "", phone_number)
    if len(normalized_phone) < 7:
        raise HTTPException(status_code=400, detail="Invalid phone number format.")

    # Cross-account block: check if this phone was already used on a different account
    existing_phone_claim = await storage.get("phone_trials", normalized_phone)
    if existing_phone_claim and existing_phone_claim.get("uid") != uid:
        raise HTTPException(
            status_code=403,
            detail="This phone number has already been used to claim a free trial on another account.",
        )

    allowed_phone = await storage.check_and_increment("phone_trials_count", normalized_phone, "used", 1)
    if not allowed_phone:
        raise HTTPException(status_code=403, detail="This phone number has already been used to claim a free trial.")

    existing = await _get_trial_info(uid)
    if existing:
        return {
            "status": "already_active",
            "trial_tier": FREE_TRIAL_TIER,
            "days_remaining": existing["days_remaining"],
            "message": f"You have {existing['days_remaining']} days of full {FREE_TRIAL_TIER.title()} access.",
        }

    ip_key = client_ip.replace(".", "_").replace(":", "_")
    allowed_ip = await storage.check_and_increment("ip_trials", ip_key, "count", 3)
    if not allowed_ip:
        raise HTTPException(status_code=429, detail="Too many trials activated from this network.")

    result = await activate_trial(uid, normalized_phone, ip_key)
    return {
        "status": "activated",
        "trial_tier": FREE_TRIAL_TIER,
        "days_remaining": result["days_remaining"],
        "message": f"You have {result['days_remaining']} days of full {FREE_TRIAL_TIER.title()} access. No credit card needed.",
    }


# ──────────────────────────────────────────────
#  Status Endpoint
# ──────────────────────────────────────────────

class SubscriptionStatus(BaseModel):
    tier: str = Field(default="observer")
    is_active: bool = Field(default=True)
    analyses_per_day: int = Field(default=0)
    tokens_used_today: int = Field(default=0)
    analyses_used_today: int = Field(default=0)
    is_trial: bool = Field(default=False)
    trial_days_remaining: int = Field(default=0)
    trial_tier: str | None = Field(default=None)
    portal_url: str | None = Field(default=None)


@router.get("/status", response_model=SubscriptionStatus, summary="Get subscription status")
@limiter.limit("30/minute")
async def get_subscription_status(request: Request, uid: str = Depends(get_current_user)):
    from storage import storage

    tier_name = await get_user_tier_async(uid)
    config = get_tier_config(tier_name)

    today = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    tokens_data    = await storage.get("tokens_used", f"{uid}_{today}") or {"count": 0}
    analysis_data  = await storage.get("analysis_counts", f"{uid}_{today}") or {"count": 0}

    trial_info  = await _get_trial_info(uid)
    has_paid    = _user_tiers.get(uid) is not None
    is_trial    = trial_info is not None and trial_info.get("is_active", False) and not has_paid

    portal_urls = _user_portal_urls.get(uid, {})
    portal_url  = portal_urls.get("update_payment_method") or (PRICING_URL if tier_name == "observer" else None)

    return SubscriptionStatus(
        tier=tier_name,
        is_active=True,
        analyses_per_day=config["analyses_per_day"],
        tokens_used_today=tokens_data.get("count", 0),
        analyses_used_today=analysis_data.get("count", 0),
        is_trial=is_trial,
        trial_days_remaining=trial_info["days_remaining"] if trial_info else 0,
        trial_tier=FREE_TRIAL_TIER if is_trial else None,
        portal_url=portal_url,
    )


# ──────────────────────────────────────────────
#  Portal / Billing Management Endpoint
# ──────────────────────────────────────────────

@router.get("/portal", summary="Get billing management URL")
async def get_billing_portal(uid: str = Depends(get_current_user)):
    """
    Returns the URL where the user can manage their subscription.
    - Paddle subscribers: returns Paddle's self-service update_payment_method URL
    - Paystack subscribers: returns the website billing/pricing page
    - Observer/trial users: returns the website pricing page for upgrade
    """
    portal_urls = _user_portal_urls.get(uid, {})
    url = portal_urls.get("update_payment_method") or PRICING_URL
    return {"portal_url": url, "cancel_url": portal_urls.get("cancel", PRICING_URL)}


# ──────────────────────────────────────────────
#  Pricing Tiers Endpoint (Public)
# ──────────────────────────────────────────────

@router.get("/tiers", summary="Get all available pricing tiers")
async def get_pricing_tiers():
    """Returns the full pricing structure (public endpoint, no auth needed)."""
    return {
        "tiers": {
            name: {
                "price_monthly": config["price_monthly"],
                "analyses_per_day": "Unlimited" if config["analyses_per_day"] >= 999 else config["analyses_per_day"],
                "features": {k: v for k, v in config.items() if k not in ("price_monthly", "analyses_per_day")},
            }
            for name, config in TIER_CONFIG.items()
        },
        "gateways": {
            "global": "Paddle (Cards, PayPal, Apple Pay, Google Pay)",
            "africa": "Paystack (Bank Transfer, USSD, Mobile Money, Verve)",
        },
        "core_promise": "Every analysis uses all 11 AI agents. Quality never changes. Only quantity and extra tools differ.",
    }
