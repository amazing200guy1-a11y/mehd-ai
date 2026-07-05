import os
import httpx
import logging
from typing import List, Tuple
from models import TradeOrder, InternalTradeOrder, AccountHealth, RiskDecision

logger = logging.getLogger("mehd.risk_client")


class RiskClient:
    """
    Communicates with the isolated Risk Microservice on port 8001.
    
    CRITICAL DESIGN NOTE (BUG FIX 2026-04-21):
    The internal token is read LAZILY from the environment on every request,
    NOT cached at construction time. This is because:
      1. risk_client = RiskClient() runs at import time (via state.py)
      2. main.py lifespan generates RISK_INTERNAL_TOKEN AFTER imports
      3. If we cached the token at __init__, it would always be "fallback-token"
      4. The risk microservice would reject every call with 403
    
    By reading os.environ on each request, we always use the real token.
    """

    def __init__(self, base_url: str | None = None):
        if base_url is None:
            base_url = os.environ.get("RISK_MICROSERVICE_URL", "http://127.0.0.1:8001")
        self.base_url = base_url
        # NOTE: Do NOT cache the token here — it hasn't been generated yet.
        # We create a bare client and inject the token per-request via _headers().
        self.client = httpx.AsyncClient(
            base_url=self.base_url,
            timeout=10.0,
        )

    def _headers(self) -> dict:
        """Read the internal token fresh from the environment on every call."""
        token = os.environ.get("RISK_INTERNAL_TOKEN", "")
        if not token:
            logger.warning("RISK_INTERNAL_TOKEN not set — risk calls will be rejected")
        return {"x-internal-token": token}

    async def get_account_health(self) -> AccountHealth:
        try:
            resp = await self.client.get("/health", headers=self._headers())
            resp.raise_for_status()
            return AccountHealth(**resp.json())
        except Exception as e:
            logger.error("RiskService down: %s", e)
            # Fallback mock for graceful UI if microservice takes a second to boot
            return AccountHealth(balance=0.0, equity=0.0, is_locked=True, daily_drawdown_pct=0.0, lock_reason="RISK_SERVICE_UNAVAILABLE")

    async def get_gateway_status(self) -> dict:
        try:
            resp = await self.client.get("/status", headers=self._headers())
            resp.raise_for_status()
            return resp.json()
        except Exception as e:
            logger.error("RiskService down: %s", e)
            return {"status": "RISK_SERVICE_OFFLINE"}

    async def check_math_veto(self, math_votes: List) -> Tuple[bool, str]:
        try:
            payload = [v.model_dump(mode="json") for v in math_votes]
            resp = await self.client.post("/veto", json={"math_votes": payload}, headers=self._headers())
            resp.raise_for_status()
            data = resp.json()
            return data["vetoed"], data["reason"]
        except Exception as e:
            logger.error("RiskService down: %s", e)
            # Fail closed on veto check
            return True, "Risk Service Unavailable - All trades blocked"

    async def evaluate_and_execute(self, order: InternalTradeOrder, current_price: float, current_spread: float, user_id: str) -> dict:
        try:
            # We dump to json compliant format using pydantic
            payload = {
                "order": order.model_dump(mode="json"),
                "current_price": current_price,
                "current_spread": current_spread,
                "user_id": user_id
            }
            resp = await self.client.post("/execute", json=payload, headers=self._headers())
            resp.raise_for_status()
            data = resp.json()
            if data.get("decision"):
                data["decision"] = RiskDecision(**data["decision"])
            return data
        except Exception as e:
            logger.error("RiskService execute failed: %s", e)
            return {
                "approved": False,
                "decision": RiskDecision(
                    id="fail_closed",
                    symbol=order.symbol,
                    approved=False,
                    calculated_lot_size=0.0,
                    rejection_reason="RISK_SERVICE_UNAVAILABLE"
                ),
                "seal_valid": False,
                "execution_result": None
            }


risk_client = RiskClient()
