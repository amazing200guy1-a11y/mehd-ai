"""
Mehd AI — Data Models (Pydantic v2)
====================================
Every piece of data that flows through Mehd AI has a strict shape.
No field can be missing, no value can be the wrong type, no number
can exceed its allowed range. In a financial system, a single
mistyped field can mean real money lost. These models prevent that.
"""

from __future__ import annotations

from datetime import datetime, timezone
from enum import Enum
from typing import Optional
from uuid import UUID, uuid4

from pydantic import BaseModel, Field, field_validator


# ──────────────────────────────────────────────
#  Enums — the ONLY directions the system can express
# ──────────────────────────────────────────────

class Direction(str, Enum):
    """
    A trade can only ever go in one of three directions.
    By making this an enum, it is impossible for any part
    of the system to invent a fourth option like 'MAYBE'.
    """
    BUY = "BUY"
    SELL = "SELL"
    HOLD = "HOLD"


# ──────────────────────────────────────────────
#  MarketSnapshot — what the market looks like RIGHT NOW
# ──────────────────────────────────────────────

class MarketSnapshot(BaseModel):
    """
    A frozen picture of a currency pair at one moment in time.
    The frontend sends this to the backend so every AI model
    is analyzing the exact same data — no stale prices.
    """
    id: UUID = Field(
        default_factory=uuid4,
        description="Unique ID for this specific snapshot instance",
    )
    symbol: str = Field(
        ...,
        min_length=6,
        max_length=10,
        description="Currency pair, e.g. 'EURUSD' or 'EUR/USD'",
        examples=["EURUSD"],
    )
    bid: float = Field(..., gt=0, description="Current bid price")
    ask: float = Field(..., gt=0, description="Current ask price")
    spread: float = Field(..., ge=0, description="Ask minus bid, in pips")
    timestamp: datetime = Field(
        default_factory=lambda: datetime.now(timezone.utc),
        description="When this snapshot was captured (UTC)",
    )
    open: float = Field(..., gt=0, description="Period open price")
    high: float = Field(..., gt=0, description="Period high price")
    low: float = Field(..., gt=0, description="Period low price")
    close: float = Field(..., gt=0, description="Period close price")
    volume: float = Field(..., ge=0, description="Trade volume in the period")

    @field_validator("ask")
    @classmethod
    def ask_must_be_gte_bid(cls, v: float, info) -> float:
        bid = info.data.get("bid")
        if bid is not None and v < bid:
            raise ValueError("Ask price cannot be lower than bid price")
        return v

    @field_validator("high")
    @classmethod
    def high_must_be_gte_low(cls, v: float, info) -> float:
        low = info.data.get("low")
        if low is not None and v < low:
            raise ValueError("High price cannot be lower than low price")
        return v


# ──────────────────────────────────────────────
#  AIVote — one model's opinion
# ──────────────────────────────────────────────

class AIVote(BaseModel):
    """
    Each of the 9 AI models returns exactly this shape.
    - model_name identifies WHO voted
    - direction is BUY, SELL, or HOLD — nothing else
    - confidence is 0-100 — how sure the model is
    - reasoning is plain English so the trader can read WHY
    """
    model_name: str = Field(
        ...,
        min_length=1,
        description="Name of the AI model, e.g. 'grok', 'claude'",
    )
    snapshot_id: UUID = Field(
        ...,
        description="The exact MarketSnapshot ID this model analyzed",
    )
    direction: Direction = Field(
        ...,
        description="The model's recommended trade direction",
    )
    confidence: float = Field(
        ...,
        ge=0,
        le=100,
        description="Confidence score from 0 (no idea) to 100 (certain)",
    )
    reasoning: str = Field(
        ...,
        min_length=1,
        description="Plain English explanation of why this direction was chosen",
    )


# ──────────────────────────────────────────────
#  ConsensusResult — the council's combined verdict
# ──────────────────────────────────────────────

class ConsensusResult(BaseModel):
    """
    After all 9 models vote, this object holds:
    - every individual vote
    - the final direction the majority chose
    - the percentage that agreed
    - whether the system will allow the trade to proceed
    """
    votes: list[AIVote] = Field(
        ...,
        description="All individual AI model votes",
    )
    final_direction: Direction = Field(
        ...,
        description="The direction chosen by the majority of models",
    )
    consensus_percentage: float = Field(
        ...,
        ge=0,
        le=100,
        description="Percentage of models that agreed on the final direction",
    )
    proceed: bool = Field(
        ...,
        description="True if consensus is strong enough to allow trading",
    )
    rejection_reason: Optional[str] = Field(
        default=None,
        description="If proceed is False, explains why (e.g. CALCULATION_MISMATCH)",
    )
    timestamp: datetime = Field(
        default_factory=lambda: datetime.now(timezone.utc),
        description="When the consensus was calculated (UTC)",
    )


# ──────────────────────────────────────────────
#  TradeOrder — what the trader wants to do
# ──────────────────────────────────────────────

class TradeOrder(BaseModel):
    """
    A request to open a trade. The risk engine will
    inspect every field before allowing execution.
    """
    symbol: str = Field(
        ...,
        min_length=6,
        max_length=10,
        description="Currency pair to trade",
        examples=["EURUSD"],
    )
    direction: Direction = Field(
        ...,
        description="BUY or SELL (HOLD would not make sense here)",
    )
    lot_size: float = Field(
        ...,
        gt=0,
        le=100.0,
        description="Position size in lots (0.01 = micro, 1.0 = standard)",
    )
    stop_loss: Optional[float] = Field(
        default=None,
        gt=0,
        description="Stop-loss price — the risk engine REQUIRES this",
    )
    take_profit: Optional[float] = Field(
        default=None,
        gt=0,
        description="Take-profit price — optional but recommended",
    )
    risk_percentage: float = Field(
        default=1.0,
        gt=0,
        le=1.0,
        description="Max percentage of account balance to risk (capped at 1%)",
    )
    math_layer_votes: Optional[list[AIVote]] = Field(
        default=None,
        description="Votes from the underlying Math Layer, for kernel override",
    )
    votes: Optional[list[AIVote]] = Field(
        default=None,
        description="All individual AI model votes for generating the brief",
    )

# ──────────────────────────────────────────────
#  ExecutiveBrief — The Audit Trail
# ──────────────────────────────────────────────

class ExecutiveBrief(BaseModel):
    trade_id: UUID
    symbol: str
    timestamp: datetime
    final_verdict: str
    consensus_score: str
    sentiment_layer: dict[str, str]
    strategy_layer: dict[str, str]
    math_layer: dict[str, str]
    risk_verification: dict[str, str]
    decision_basis: str


# ──────────────────────────────────────────────
#  AccountHealth — how is the trader's account doing?
# ──────────────────────────────────────────────

class AccountHealth(BaseModel):
    """
    A real-time snapshot of the trader's account.
    If is_locked is True, the system has shut down
    trading for safety — the lock_reason explains why.
    """
    balance: float = Field(
        ...,
        ge=0,
        description="Current account balance in USD",
    )
    equity: float = Field(
        ...,
        ge=0,
        description="Balance plus/minus unrealised P&L",
    )
    daily_drawdown_pct: float = Field(
        default=0.0,
        ge=0,
        le=100,
        description="How much the account has lost today as a percentage",
    )
    is_locked: bool = Field(
        default=False,
        description="True if the kill-switch has been triggered",
    )
    lock_reason: Optional[str] = Field(
        default=None,
        description="Why the account was locked, e.g. 'Daily drawdown exceeded 3%'",
    )
    lock_expiry: Optional[datetime] = Field(
        default=None,
        description="When the lock will automatically lift (UTC)",
    )


# ──────────────────────────────────────────────
#  RiskDecision — the risk engine's final word
# ──────────────────────────────────────────────

class RiskDecision(BaseModel):
    """
    After the HardRiskKernel inspects a TradeOrder, it
    returns this. If approved is False, the trade is dead —
    no override, no exception, no workaround.
    """
    id: UUID = Field(
        default_factory=uuid4,
        description="Unique ID for this risk decision (for audit trail)",
    )
    approved: bool = Field(
        ...,
        description="True if the trade passed all risk checks",
    )
    calculated_lot_size: float = Field(
        ...,
        ge=0,
        description="The lot size the risk engine calculated as safe",
    )
    stop_loss: float = Field(
        ...,
        gt=0,
        description="The stop-loss price approved by the risk engine",
    )
    take_profit: Optional[float] = Field(
        default=None,
        gt=0,
        description="The take-profit price, if provided",
    )
    rejection_reason: Optional[str] = Field(
        default=None,
        description="If rejected, the exact reason why",
    )
    timestamp: datetime = Field(
        default_factory=lambda: datetime.now(timezone.utc),
        description="When this decision was made (UTC)",
    )
