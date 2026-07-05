"""
Mehd AI — Risk Microservice
=============================
This is the isolated "Separate Room" for the Risk Guard.
It runs as its own standalone application on port 8001.

Even if the main web server is compromised, attackers cannot
modify the rules loaded into this process memory. The only way
to execute a trade is to pass the strict validation rules of this API.
"""

import os
from fastapi import FastAPI, HTTPException, Security, Depends
from fastapi.security.api_key import APIKeyHeader
from pydantic import BaseModel
from typing import List, Dict, Any, Optional

from risk_engine import HardRiskKernel
from risk_gateway import RiskGateway
from models import TradeOrder, RiskDecision, InternalTradeOrder, AIVote

api_key_header = APIKeyHeader(name="x-internal-token", auto_error=True)

def verify_internal_token(api_key: str = Security(api_key_header)):
    expected = os.environ.get("RISK_INTERNAL_TOKEN")
    if not expected or api_key != expected:
        raise HTTPException(status_code=403, detail="Unauthorized internal access")

app = FastAPI(
    title="Mehd AI Risk Microservice",
)

# Auth dependency — applied to sensitive endpoints only.
# /health and /status are exempt so Docker healthchecks work
# (they can't send the x-internal-token header).
# This is safe because port 8001 is no longer exposed to the host network.
_auth = [Depends(verify_internal_token)]

# Initialize the critical risk engine
kernel = HardRiskKernel()
gateway = RiskGateway(kernel)


class ExecuteRequest(BaseModel):
    order: InternalTradeOrder
    current_price: float
    current_spread: float
    user_id: str


class VetoRequest(BaseModel):
    math_votes: List[AIVote]


@app.get("/health")
def get_health():
    """Returns the current account health snapshot. No auth — used by Docker healthcheck."""
    return kernel.get_account_health()


@app.get("/status")
def get_status():
    """Returns the integrity status of the Gateway. No auth — non-sensitive."""
    status = gateway.get_gateway_status()
    return {"status": status["status"], "boot_time": status["boot_time"]}


@app.post("/veto", dependencies=_auth)
async def check_veto(req: VetoRequest):
    """Evaluates the Math Layer for vetos based on math model confidence."""
    vetoed, reason = kernel.check_math_veto(req.math_votes)
    return {"vetoed": vetoed, "reason": reason}


@app.post("/execute", dependencies=_auth)
async def execute_trade(req: ExecuteRequest):
    """The only way to execute a trade."""
    result = await gateway.evaluate_and_execute(
        order=req.order,
        current_price=req.current_price,
        current_spread=req.current_spread,
        user_id=req.user_id
    )
    return result
