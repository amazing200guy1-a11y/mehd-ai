"""
Mehd AI — Payment Routes (Stripe Integration)
================================================
THE BATTERY SLOT: Everything is wired. When STRIPE_SECRET_KEY
is set in .env, payments just work. When it's empty, all
endpoints return a friendly "payments not configured" message.

Endpoints:
    POST /payments/create-checkout   → Stripe Checkout for tier upgrade
    POST /payments/webhook           → Stripe webhook (subscription events)
    GET  /payments/status            → Current user's subscription status
    POST /payments/portal            → Stripe Customer Portal (manage billing)

Security:
    - Webhook signature verification (prevents fake events)
    - Server-side tier enforcement (client can never set its own tier)
    - All tier changes logged to audit trail
"""

from __future__ import annotations

import logging
import os
import time
from collections import deque
from datetime import datetime, timezone

from fastapi import APIRouter, HTTPException, Request, Depends, Header
from pydantic import BaseModel, Field
from slowapi import Limiter

from auth import get_current_user, get_real_ip, get_uid_rate_key

logger = logging.getLogger("mehd.routes.payments")
router = APIRouter(prefix="/payments", tags=["Payments"])
limiter = Limiter(key_func=get_uid_rate_key)

# ──────────────────────────────────────────────
#  Configuration — The Battery Slot
# ──────────────────────────────────────────────

STRIPE_SECRET_KEY = os.getenv("STRIPE_SECRET_KEY", "")
STRIPE_WEBHOOK_SECRET = os.getenv("STRIPE_WEBHOOK_SECRET", "")

# Stripe Price IDs — created in Stripe Dashboard, pasted here
PRICE_IDS = {
    "core":          os.getenv("STRIPE_PRICE_CORE", ""),
    "precision":     os.getenv("STRIPE_PRICE_PRECISION", ""),
    "institutional": os.getenv("STRIPE_PRICE_INSTITUTIONAL", ""),
}

# Reverse lookup: Stripe price_id → our tier name
_PRICE_TO_TIER: dict[str, str] = {}

# Webhook idempotency — tracks processed Stripe event IDs to prevent
# duplicate processing (e.g., Stripe retries or Dashboard replays).
# SECURITY HARDENED: L1 = in-memory deque (fast), L2 = persistent storage (survives restarts).
# Both are checked before processing. Oldest events are evicted from L1 only.
_processed_event_ids: deque[str] = deque(maxlen=10_000)

# SECURITY: Server-controlled redirect URLs — NEVER accept from client.
# This prevents open-redirect phishing attacks where an attacker sends
# a modified request that redirects paying users to a fake success page.
CHECKOUT_SUCCESS_URL = os.getenv("CHECKOUT_SUCCESS_URL", "https://mehdai.com/success.html")
CHECKOUT_CANCEL_URL = os.getenv("CHECKOUT_CANCEL_URL", "https://mehdai.com/#pricing")

# ──────────────────────────────────────────────
#  Free Trial System — The Duolingo Play
# ──────────────────────────────────────────────
# New users get 3 days of full Institutional access (no credit card).
# During those 3 days they build up Mistake DNA, trade history, and
# Journey progress — data they emotionally can't abandon.
# When the trial expires, they can SEE their data but can't get new
# analyses. The loss hurts → they upgrade.
FREE_TRIAL_DAYS = 3
FREE_TRIAL_TIER = "institutional"  # Give them the full $99/month experience

def _is_configured() -> bool:
    """Check if Stripe is wired up."""
    return bool(STRIPE_SECRET_KEY)

def _get_stripe():
    """Lazy import stripe to avoid crash when not installed."""
    try:
        import stripe
        stripe.api_key = STRIPE_SECRET_KEY
        return stripe
    except ImportError:
        logger.error("stripe package not installed. Run: pip install stripe")
        return None

def _build_price_lookup():
    """Build the reverse price→tier map from env vars."""
    global _PRICE_TO_TIER
    _PRICE_TO_TIER = {v: k for k, v in PRICE_IDS.items() if v}


# Build on import
_build_price_lookup()


# ──────────────────────────────────────────────
#  Request / Response Models
# ──────────────────────────────────────────────

class CheckoutRequest(BaseModel):
    tier: str = Field(
        ...,
        description="Tier to subscribe to: 'core', 'precision', or 'institutional'",
        examples=["institutional"],
    )
    # SECURITY: success_url and cancel_url are NO LONGER accepted from the client.
    # They are locked server-side to prevent open-redirect phishing attacks.
    # See CHECKOUT_SUCCESS_URL and CHECKOUT_CANCEL_URL constants above.

class SubscriptionStatus(BaseModel):
    tier: str = Field(default="observer", description="Current tier name")
    is_active: bool = Field(default=True, description="Whether subscription is active")
    analyses_per_day: int = Field(default=1, description="How many analyses allowed per day")
    current_period_end: str | None = Field(default=None, description="When current billing period ends")
    cancel_at_period_end: bool = Field(default=False, description="Whether subscription will cancel at period end")
    manage_url: str | None = Field(default=None, description="URL to manage billing (Stripe Portal)")
    tokens_used_today: int = Field(default=0, description="Number of broadcast reveals used today")
    analyses_used_today: int = Field(default=0, description="Number of manual analyses used today")
    # Trial fields
    is_trial: bool = Field(default=False, description="Whether user is on free trial")
    trial_days_remaining: int = Field(default=0, description="Days left in trial (0 = expired or not on trial)")
    trial_tier: str | None = Field(default=None, description="Which tier the trial grants")


# ──────────────────────────────────────────────
#  Tier Configuration (Single Source of Truth)
# ──────────────────────────────────────────────

TIER_CONFIG = {
    "observer": {
        "display_name": "Observer Mode",
        "analyses_per_week": 1,
        "analyses_per_day": 0,
        "sniper_access": True, # UNLOCKED
        "autopilot_mode": "assisted", # UNLOCKED: Even free users get the Spear (limited by volume)
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
        "autopilot_mode": "assisted", # UNLOCKED: Now includes the Spear (Assisted)
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
        "autopilot_mode": "full", # UNLOCKED: Now includes Full Autonomy
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

# ── BACKWARD-COMPATIBILITY: Legacy Tier Name Translation ──────────
# Existing Firestore records may still contain old tier names.
# This map ensures zero-downtime migration without a database sweep.
_LEGACY_TIER_ALIASES = {
    "scout": "observer",
    "guardian": "core",
    "operative": "institutional",
}

def get_tier_config(tier_name: str) -> dict:
    """Get the config for a tier. Translates legacy names. Defaults to observer."""
    # Translate legacy tier names to new names
    resolved = _LEGACY_TIER_ALIASES.get(tier_name, tier_name)
    return TIER_CONFIG.get(resolved, TIER_CONFIG["observer"])


# ──────────────────────────────────────────────
#  In-memory tier map (populated by webhooks)
#  HARDENED: Rebuilt from storage on startup via rebuild_tier_caches()
# ──────────────────────────────────────────────

_user_tiers: dict[str, str] = {}           # uid → tier name
_user_stripe_ids: dict[str, str] = {}      # uid → stripe customer id
_stripe_to_uid: dict[str, str] = {}        # stripe customer id → uid


def get_user_tier(uid: str) -> str:
    """
    Get the user's current tier name (sync, cache-only).
    Returns 'observer' for any user not in the in-memory cache.
    
    NOTE: For authoritative lookups that check persistent storage
    and trial status, use get_user_tier_async() instead.
    This sync version exists only for hot-path code that cannot await.
    """
    return _user_tiers.get(uid, "observer")


def set_user_tier(uid: str, tier: str) -> None:
    """Set the user's tier (called by webhook handler)."""
    old_tier = _user_tiers.get(uid, "observer")
    _user_tiers[uid] = tier
    # Also update the async TTL cache so upgrades are instant
    _async_tier_cache[uid] = tier
    logger.info("TIER CHANGE: User %s: %s → %s", uid, old_tier, tier)

    # Persist to storage (survives restarts)
    try:
        import asyncio
        from storage import storage
        
        # 1. Update the user_tiers audit record
        asyncio.create_task(storage.set("user_tiers", uid, {
            "tier": tier,
            "updated_at": datetime.now(timezone.utc).isoformat(),
            "previous_tier": old_tier,
        }))

        # 2. Sync tier to AutopilotConfig for priority routing
        async def sync_tier_to_autopilot():
            raw_cfg = await storage.get("autopilot_configs", uid)
            if raw_cfg:
                raw_cfg["tier"] = tier
                await storage.set("autopilot_configs", uid, raw_cfg)
        
        asyncio.create_task(sync_tier_to_autopilot())

    except Exception as e:
        logger.warning("Could not persist tier change: %s", e)


async def persist_stripe_mapping(uid: str, customer_id: str) -> None:
    """
    Persist the UID ↔ Stripe Customer ID mapping to storage.
    This is critical for surviving restarts — without it, subscription
    updates (upgrades, cancellations) after a restart silently fail
    because _stripe_to_uid is empty.
    """
    from storage import storage
    _user_stripe_ids[uid] = customer_id
    _stripe_to_uid[customer_id] = uid
    await storage.set("stripe_mappings", uid, {
        "stripe_customer_id": customer_id,
        "updated_at": datetime.now(timezone.utc).isoformat(),
    })
    logger.info("STRIPE MAPPING PERSISTED: %s ↔ %s", uid, customer_id[:12] + "...")


async def rebuild_tier_caches() -> None:
    """
    Rebuild ALL in-memory caches from persistent storage on startup.
    
    WHY THIS EXISTS:
    Before this function, a server restart meant:
      - All paying users fell back to 'observer' (free tier)
      - _stripe_to_uid was empty, so subscription changes were lost
      - _user_stripe_ids was empty, so checkout sessions lost customer context
    
    Now, on every startup:
      1. Load all user_tiers → rebuild _user_tiers
      2. Load all stripe_mappings → rebuild _user_stripe_ids and _stripe_to_uid
    
    Called from main.py lifespan() during startup.
    """
    from storage import storage
    
    rebuilt_tiers = 0
    rebuilt_stripe = 0
    
    # 1. Rebuild tier cache
    try:
        tier_keys = await storage.list_keys("user_tiers")
        for uid in tier_keys:
            tier_data = await storage.get("user_tiers", uid)
            if tier_data and "tier" in tier_data:
                _user_tiers[uid] = tier_data["tier"]
                rebuilt_tiers += 1
    except Exception as e:
        logger.warning("Could not rebuild tier cache: %s", e)
    
    # 2. Rebuild Stripe customer mappings
    try:
        stripe_keys = await storage.list_keys("stripe_mappings")
        for uid in stripe_keys:
            mapping = await storage.get("stripe_mappings", uid)
            if mapping and "stripe_customer_id" in mapping:
                cid = mapping["stripe_customer_id"]
                _user_stripe_ids[uid] = cid
                _stripe_to_uid[cid] = uid
                rebuilt_stripe += 1
    except Exception as e:
        logger.warning("Could not rebuild Stripe mappings: %s", e)
    
    logger.info(
        "✓ Tier caches rebuilt: %d tiers, %d Stripe mappings loaded from storage",
        rebuilt_tiers, rebuilt_stripe,
    )


# ──────────────────────────────────────────────
#  Endpoints
# ──────────────────────────────────────────────

@router.post("/create-checkout", summary="Create a Stripe Checkout session")
async def create_checkout(req: CheckoutRequest, uid: str = Depends(get_current_user)):
    """
    Creates a Stripe Checkout session for the given tier.
    Returns a URL to redirect the user to Stripe's hosted checkout page.
    """
    if not _is_configured():
        raise HTTPException(
            status_code=503,
            detail="Payments are not yet configured. Coming soon — paste STRIPE_SECRET_KEY to activate.",
        )

    stripe = _get_stripe()
    if not stripe:
        raise HTTPException(status_code=503, detail="Stripe library not available.")

    # Validate tier
    tier = req.tier.lower()
    if tier not in PRICE_IDS:
        raise HTTPException(status_code=400, detail=f"Invalid tier: '{tier}'. Choose core, precision, or institutional.")

    price_id = PRICE_IDS[tier]
    if not price_id:
        raise HTTPException(
            status_code=400,
            detail=f"Stripe price ID for '{tier}' not configured. Set STRIPE_PRICE_{tier.upper()} in .env",
        )

    try:
        # Check if user already has a Stripe customer ID
        customer_id = _user_stripe_ids.get(uid)

        checkout_params = {
            "mode": "subscription",
            "payment_method_types": ["card"],
            "line_items": [{"price": price_id, "quantity": 1}],
            "success_url": CHECKOUT_SUCCESS_URL + "?session_id={CHECKOUT_SESSION_ID}",
            "cancel_url": CHECKOUT_CANCEL_URL,
            "metadata": {"mehd_uid": uid, "tier": tier},
            "subscription_data": {"metadata": {"mehd_uid": uid, "tier": tier}},
        }

        if customer_id:
            checkout_params["customer"] = customer_id
        else:
            checkout_params["customer_creation"] = "always"

        session = stripe.checkout.Session.create(**checkout_params)

        logger.info("Checkout session created for user %s, tier %s", uid, tier)
        return {"checkout_url": session.url, "session_id": session.id}

    except Exception as e:
        logger.error("Stripe checkout failed: %s", e)
        raise HTTPException(status_code=500, detail="Could not create checkout session. Please try again.")


@router.post("/webhook", summary="Stripe webhook handler", include_in_schema=False)
@limiter.limit("100/minute")
async def stripe_webhook(request: Request):
    """
    Handles Stripe webhook events:
    - checkout.session.completed → user subscribed, upgrade tier
    - customer.subscription.updated → plan changed
    - customer.subscription.deleted → cancelled, downgrade to observer
    - invoice.payment_failed → warn user, don't downgrade immediately
    """
    if not _is_configured():
        raise HTTPException(status_code=503, detail="Payments not configured.")

    stripe = _get_stripe()
    if not stripe:
        raise HTTPException(status_code=503, detail="Stripe library not available.")

    # Read raw body for signature verification
    payload = await request.body()
    sig_header = request.headers.get("stripe-signature", "")

    if not STRIPE_WEBHOOK_SECRET:
        logger.critical("WEBHOOK: Failed because STRIPE_WEBHOOK_SECRET is missing from environment. Bouncing request to prevent spoofing.")
        # Return 400, NOT 500. Stripe treats 500 as "server broken, retry later"
        # and will flood us with retries for 3 days. 400 = permanent rejection.
        raise HTTPException(status_code=400, detail="Webhook not configured")

    try:
        event = stripe.Webhook.construct_event(payload, sig_header, STRIPE_WEBHOOK_SECRET)
    except stripe.error.SignatureVerificationError:
        logger.critical("WEBHOOK: Invalid signature — possible tampering attempt")
        raise HTTPException(status_code=400, detail="Invalid webhook signature")
    except Exception as e:
        logger.error("WEBHOOK: Failed to parse event: %s", e)
        raise HTTPException(status_code=400, detail="Invalid webhook payload")

    # Extract event ID and type
    event_id = event.get("id", "") if isinstance(event, dict) else event.id
    event_type = event.get("type", "") if isinstance(event, dict) else event.type
    data = event.get("data", {}).get("object", {}) if isinstance(event, dict) else event.data.object

    logger.info("WEBHOOK: Received event: %s (id: %s)", event_type, event_id)

    # IDEMPOTENCY CHECK — prevent duplicate event processing.
    # Stripe can re-deliver the same event (network retry, Dashboard replay).
    # Without this, tier upgrades or billing credits could be applied twice.
    # HARDENED: Checks BOTH in-memory cache AND persistent storage.
    if event_id:
        if event_id in _processed_event_ids:
            logger.info("WEBHOOK: Skipping already-processed event %s (L1 cache)", event_id)
            return {"status": "already_processed"}
        # L2: Check persistent storage (survives restarts)
        from storage import storage
        persisted = await storage.get("webhook_events", event_id)
        if persisted:
            _processed_event_ids.append(event_id)  # Warm L1 cache
            logger.info("WEBHOOK: Skipping already-processed event %s (L2 storage)", event_id)
            return {"status": "already_processed"}

    # Record this event ID in BOTH L1 and L2
    if event_id:
        _processed_event_ids.append(event_id)
        from storage import storage
        await storage.set("webhook_events", event_id, {
            "processed_at": datetime.now(timezone.utc).isoformat(),
            "event_type": event_type,
        })

    # ── Handle: Checkout completed (new subscription) ──
    if event_type == "checkout.session.completed":
        metadata = data.get("metadata", {}) if isinstance(data, dict) else (data.metadata or {})
        uid = metadata.get("mehd_uid", "")
        tier = metadata.get("tier", "")
        customer_id = data.get("customer", "") if isinstance(data, dict) else data.customer

        if uid and tier:
            set_user_tier(uid, tier)
            if customer_id:
                await persist_stripe_mapping(uid, customer_id)
            logger.info("SUBSCRIPTION ACTIVATED: User %s → %s tier", uid, tier)

    # ── Handle: Subscription updated (plan change) ──
    elif event_type == "customer.subscription.updated":
        customer_id = data.get("customer", "") if isinstance(data, dict) else data.customer
        uid = _stripe_to_uid.get(customer_id, "")

        if uid:
            # Find which tier they're on now
            items = data.get("items", {}).get("data", []) if isinstance(data, dict) else data.items.data
            for item in items:
                price_id = item.get("price", {}).get("id", "") if isinstance(item, dict) else item.price.id
                new_tier = _PRICE_TO_TIER.get(price_id, "")
                if new_tier:
                    set_user_tier(uid, new_tier)
                    logger.info("SUBSCRIPTION CHANGED: User %s → %s tier", uid, new_tier)

    # ── Handle: Subscription deleted (cancelled) ──
    elif event_type == "customer.subscription.deleted":
        customer_id = data.get("customer", "") if isinstance(data, dict) else data.customer
        uid = _stripe_to_uid.get(customer_id, "")
        if uid:
            # FIX: If they cancel but still have an active trial, don't drop them to observer.
            trial_info = await _get_trial_info(uid)
            if trial_info and trial_info.get("days_remaining", 0) > 0:
                set_user_tier(uid, FREE_TRIAL_TIER)
                logger.info("SUBSCRIPTION CANCELLED: User %s fell back to active trial tier", uid)
            else:
                set_user_tier(uid, "observer")
                logger.info("SUBSCRIPTION CANCELLED: User %s → observer (free) tier", uid)

    # ── Handle: Payment failed (warn, don't punish immediately) ──
    elif event_type == "invoice.payment_failed":
        customer_id = data.get("customer", "") if isinstance(data, dict) else data.customer
        uid = _stripe_to_uid.get(customer_id, "")
        if uid:
            logger.warning("PAYMENT FAILED: User %s — Stripe will retry automatically", uid)

    return {"status": "ok"}


@router.get("/status", response_model=SubscriptionStatus, summary="Get subscription status")
@limiter.limit("30/minute")
async def get_subscription_status(request: Request, uid: str = Depends(get_current_user)):
    """Returns the current user's subscription tier and trial details."""
    from storage import storage

    # HARDENED: Use async tier lookup that checks persistent storage + trial
    tier_name = await get_user_tier_async(uid)
    config = get_tier_config(tier_name)

    # Fetch daily tokens used
    today = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    token_key = f"{uid}_{today}"
    tokens_used_data = await storage.get("tokens_used", token_key) or {"count": 0}
    tokens_used_today = tokens_used_data.get("count", 0)

    # Fetch daily analyses used
    today = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    analysis_key = f"{uid}_{today}"
    analysis_used_data = await storage.get("analysis_counts", analysis_key) or {"count": 0}
    analyses_used_today = analysis_used_data.get("count", 0)

    # Check trial status
    trial_info = await _get_trial_info(uid)
    is_trial = trial_info is not None and trial_info.get("is_active", False)
    # Only flag as trial if user has no paid subscription
    has_paid_sub = _user_tiers.get(uid) is not None
    if has_paid_sub:
        is_trial = False

    return SubscriptionStatus(
        tier=tier_name,
        is_active=True,
        analyses_per_day=config["analyses_per_day"],
        current_period_end=None,  # Populated from Stripe in production
        cancel_at_period_end=False,
        tokens_used_today=tokens_used_today,
        analyses_used_today=analyses_used_today,
        is_trial=is_trial,
        trial_days_remaining=trial_info["days_remaining"] if trial_info else 0,
        trial_tier=FREE_TRIAL_TIER if is_trial else None,
    )


@router.post("/activate-trial", summary="Activate the free Institutional trial")
async def activate_trial_endpoint(
    request: Request, 
    uid: str = Depends(get_current_user)
):
    """
    Activates the 3-day free Institutional trial for a new user.
    HARDENED: Requires a verified phone number to prevent infinite trial exploits.
    Headers (X-Device-ID) and IPs are spoofable. Verified SMS is costly for attackers.
    """
    client_ip = get_real_ip(request)
    from storage import storage
    from firebase_admin import auth as fb_auth
    
    # ── SECURITY (VULN-03 PATCH): Identity Attestation ──
    # Check if the user has a verified phone number linked to their Firebase account.
    user_record = fb_auth.get_user(uid)
    phone_number = getattr(user_record, 'phone_number', None)
    
    if not phone_number:
        logger.warning("SYBIL BLOCK: User %s attempted to activate trial without SMS verification.", uid)
        raise HTTPException(
            status_code=403,
            detail="To prevent abuse, a verified phone number is required to activate the free trial. Please link your phone number in Settings."
        )
        
    # FIX: Distributed Race Condition
    # Instead of an in-memory asyncio.Lock (which fails in multi-worker deployments),
    # we use the database's atomic check_and_increment to ensure a phone number
    # can only be used exactly 1 time across the entire global system.
    allowed_phone = await storage.check_and_increment("phone_trials_count", phone_number, "used", 1)
    if not allowed_phone:
         logger.critical("SYBIL EXPLOIT BLOCKED: Phone %s attempted to claim multiple trials.", phone_number)
         raise HTTPException(
             status_code=403,
             detail="This phone number has already been used to claim a free trial on another account."
         )

    # We still check if they're trying to use a completely different phone on the same account
    existing = await _get_trial_info(uid)
    if existing:
        return {
            "status": "already_active",
            "trial_tier": FREE_TRIAL_TIER,
            "days_remaining": existing["days_remaining"],
            "message": f"You have {existing['days_remaining']} days of full {FREE_TRIAL_TIER.title()} access. No credit card needed."
        }

    # Atomically check and increment IP trials
    ip_key = client_ip.replace(".", "_").replace(":", "_")
    allowed_ip = await storage.check_and_increment("ip_trials", ip_key, "count", 3)
    if not allowed_ip:
        logger.warning("SYBIL BLOCK: IP %s exceeded trial velocity limit", client_ip)
        raise HTTPException(
            status_code=429,
            detail="Too many trials activated from this network. Please upgrade to continue."
        )

    result = await activate_trial(uid, phone_number, ip_key)
    return {
        "status": "activated" if result["days_remaining"] == FREE_TRIAL_DAYS else "already_active",
        "trial_tier": FREE_TRIAL_TIER,
        "days_remaining": result["days_remaining"],
        "message": f"You have {result['days_remaining']} days of full {FREE_TRIAL_TIER.title()} access. No credit card needed."
    }


# Fast path TTL cache for all users (paid, free, trial) to prevent DB hammering
from cachetools import TTLCache
_async_tier_cache = TTLCache(maxsize=10000, ttl=300)

async def get_user_tier_async(uid: str) -> str:
    """
    Async version of get_user_tier — checks persistent storage when
    the in-memory cache misses. This is the authoritative lookup.

    HARDENED (VULN-04): Ensures paying users keep their tier after
    server restarts. The in-memory dict is a hot cache; Firestore/storage
    is the source of truth.

    Trial-aware: If a user has no paid tier but has an active trial,
    returns the trial tier (institutional) instead of observer.
    """
    # Check high-speed TTL cache first
    cached_ttl = _async_tier_cache.get(uid)
    if cached_ttl:
        return cached_ttl

    # Fast path: in-memory cache (paid subscription from webhooks/rebuild)
    cached = _user_tiers.get(uid)
    if cached and cached != "observer":
        _async_tier_cache[uid] = cached
        return cached

    # Slow path: check persistent storage (paid subscription)
    try:
        from storage import storage
        tier_data = await storage.get("user_tiers", uid)
        if tier_data and "tier" in tier_data and tier_data["tier"] != "observer":
            tier_name = tier_data["tier"]
            # Warm the cache so subsequent calls are instant
            _user_tiers[uid] = tier_name
            _async_tier_cache[uid] = tier_name
            logger.info("TIER RESTORED from storage: User %s → %s", uid, tier_name)
            return tier_name
    except Exception as e:
        logger.warning("Persistent tier lookup failed for %s: %s", uid, e)

    # Trial check: if no paid subscription, check if user has an active trial
    trial_info = await _get_trial_info(uid)
    if trial_info and trial_info.get("days_remaining", 0) > 0:
        _async_tier_cache[uid] = FREE_TRIAL_TIER
        return FREE_TRIAL_TIER  # institutional

    _async_tier_cache[uid] = "observer"
    return "observer"


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


async def activate_trial(uid: str, phone_number: str, ip_key: str) -> dict:
    """
    Activate the free trial for a new user.
    Idempotent — if trial already exists, returns existing trial info.
    This is THE conversion engine: 3 days of Operative access builds
    data (Mistake DNA, trade history) that users can't abandon.
    """
    import re as _re
    from storage import storage

    # SECURITY (SELF-CRITIQUE-05): Normalize phone number BEFORE using it as a
    # Firestore deduplication key. Without this, the same SIM card can bypass
    # the phone-burn check by submitting formatted variants:
    #   "+1 555-123-4567", "+15551234567", "5551234567" → all different keys.
    # Stripping to digits-only produces a canonical, collision-free key.
    normalized_phone = _re.sub(r"\D", "", phone_number)
    if len(normalized_phone) < 7:
        raise HTTPException(status_code=400, detail="Invalid phone number.")

    # Check if trial already exists (idempotent)
    existing = await _get_trial_info(uid)
    if existing:
        logger.info("TRIAL: User %s already has trial (days remaining: %d)", uid, existing["days_remaining"])
        return existing

    # Activate new trial
    now = datetime.now(timezone.utc)
    trial_data = {
        "activated_at": now.isoformat(),
        "trial_tier": FREE_TRIAL_TIER,
        "trial_days": FREE_TRIAL_DAYS,
    }

    await storage.set("user_trials", uid, trial_data)

    # Burn the NORMALIZED phone number so all formatting variants are blocked
    await storage.set("phone_trials", normalized_phone, {"uid": uid, "activated_at": now.isoformat()})
    
    logger.info("🔥 TRIAL ACTIVATED: User %s (Phone: %s) → %d days of %s access", uid, phone_number, FREE_TRIAL_DAYS, FREE_TRIAL_TIER)

    return {
        "activated_at": now.isoformat(),
        "days_remaining": FREE_TRIAL_DAYS,
        "is_active": True,
        "trial_tier": FREE_TRIAL_TIER,
    }


@router.post("/portal", summary="Create Stripe Customer Portal session")
async def create_portal_session(uid: str = Depends(get_current_user)):
    """
    Creates a Stripe Customer Portal session so users can:
    - Update payment method
    - Cancel subscription
    - View invoices
    - Change plans
    """
    if not _is_configured():
        raise HTTPException(status_code=503, detail="Payments not yet configured.")

    stripe = _get_stripe()
    if not stripe:
        raise HTTPException(status_code=503, detail="Stripe library not available.")

    customer_id = _user_stripe_ids.get(uid)
    if not customer_id:
        raise HTTPException(status_code=400, detail="No active subscription found. Subscribe first.")

    try:
        session = stripe.billing_portal.Session.create(
            customer=customer_id,
            return_url="https://mehdai.com/settings",
        )
        return {"portal_url": session.url}
    except Exception as e:
        logger.error("Portal session failed: %s", e)
        raise HTTPException(status_code=500, detail="Could not create billing portal.")


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
        "institutional": {
            "price": "Custom",
            "contact": "enterprise@mehdai.com",
        },
        "core_promise": "Every analysis uses all 11 AI agents. Quality never changes. Only quantity and extra tools differ.",
    }
