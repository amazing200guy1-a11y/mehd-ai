"""
Mehd AI — Data Models (Pydantic v2)
====================================
Every piece of data that flows through Mehd AI has a strict shape.
No field can be missing, no value can be the wrong type, no number
can exceed its allowed range. In a financial system, a single
mistyped field can mean real money lost. These models prevent that.
"""

from __future__ import annotations

import time
from datetime import datetime, timezone
from enum import Enum
from typing import Optional, Literal
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

class SignalPhase(str, Enum):
    """
    The lifecycle of a broadcast signal.
    FRESH: 0-5 mins. Highly actionable.
    ACTIVE: 5-30 mins. Actionable, but price may have moved.
    STALE: 30m-4h. Warning, do not trade without new analysis.
    EXPIRED: >4h. Dead signal.
    INVALIDATED: Replaced by a contrary signal.
    """
    FRESH = "FRESH"
    ACTIVE = "ACTIVE"
    STALE = "STALE"
    EXPIRED = "EXPIRED"
    INVALIDATED = "INVALIDATED"



# ──────────────────────────────────────────────
#  Unified Pip Size — SINGLE SOURCE OF TRUTH
# ──────────────────────────────────────────────

def get_pip_size(symbol: str) -> float:
    """
    Returns the pip size for a given trading instrument.
    
    This is the ONE AND ONLY place pip_size should be defined.
    All other files MUST import this function instead of
    calculating pip_size inline.
    
    Rules:
      XAU (Gold)  → 0.01  (Standard 2nd decimal place)
      JPY pairs   → 0.01  (1 pip = ¥0.01 price movement)
      All others  → 0.0001 (1 pip = $0.0001 price movement)
    """
    sym = symbol.upper().replace("/", "")
    if "XAU" in sym:
        return 0.01
    if "JPY" in sym:
        return 0.01
    return 0.0001


# ──────────────────────────────────────────────
#  DepthOfMarket — Institutional Level 2 Data
# ──────────────────────────────────────────────

class DepthOfMarket(BaseModel):
    """
    Level 2 Institutional Order Book data.
    This is the "Empty Room" ready to receive real bank volume data.
    """
    bids: list[tuple[float, float]] = Field(default_factory=list, description="List of (price, volume) tuples")
    asks: list[tuple[float, float]] = Field(default_factory=list, description="List of (price, volume) tuples")
    imbalance_ratio: float = Field(default=0.0, description="Positive = Buy pressure, Negative = Sell pressure")


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
    timestamp_ns: int = Field(
        default_factory=time.time_ns,
        description="Nanosecond exact precision for atomic consensus",
    )
    order_book_walls: Optional[str] = Field(
        default="Buyer wall at -20 pips, Seller wall at +30 pips",
        description="Aggregated deep volume liquidity nodes",
    )
    open: float = Field(..., gt=0, description="Period open price")
    high: float = Field(..., gt=0, description="Period high price")
    low: float = Field(..., gt=0, description="Period low price")
    close: float = Field(..., gt=0, description="Period close price")
    volume: float = Field(..., ge=0, description="Trade volume in the period")
    dom_data: Optional[DepthOfMarket] = Field(
        default=None,
        description="Level 2 Institutional Order Book / Depth of Market",
    )

    # ── FIX 1: Data Freshness Fields ──
    data_age_ms: int = Field(
        default=0,
        ge=0,
        description="How old this data is in milliseconds at time of serving",
    )
    data_source: str = Field(
        default="mock",
        description="Which provider delivered this tick (oanda/polygon/twelvedata/mock)",
    )
    is_live: bool = Field(
        default=False,
        description="True only if data_age_ms < 1000",
    )
    briefing: str = Field(
        default="",
        description="The Secretary's market briefing template",
    )
    latency_warning: bool = Field(
        default=False,
        description="True if data_age_ms > 3000 — trader should be cautious",
    )

    # ── Macro Trend Fields (For Tiger Mode Alignment) ──
    trend_d1: Optional[str] = Field(
        default="NEUTRAL",
        description="Daily macro trend direction (BULLISH/BEARISH/NEUTRAL)"
    )
    trend_h4: Optional[str] = Field(
        default="NEUTRAL",
        description="4-Hour macro trend direction (BULLISH/BEARISH/NEUTRAL)"
    )
    trend_h1: Optional[str] = Field(
        default="NEUTRAL",
        description="1-Hour trend direction (BULLISH/BEARISH/NEUTRAL)"
    )

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
    Each of the 11 AI agents returns exactly this shape.
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
#  FinalReviewerOutput — Strict JSON Template for Layer 4
# ──────────────────────────────────────────────

class FinalReviewerOutput(BaseModel):
    """
    Unbreakable Python mold for the 2 Reviewer AI models.
    If they hallucinate a field or give a bad value, validation fails.
    """
    action: Direction = Field(description="Strictly BUY, SELL, or HOLD")
    confidence: float = Field(ge=0.0, le=100.0, description="0 to 100 confidence score")
    reason: str = Field(description="Strictly a 1-sentence reason for the user")


# ──────────────────────────────────────────────
#  ConsensusResult — the council's combined verdict
# ──────────────────────────────────────────────

class ConsensusResult(BaseModel):
    """
    After all 11 agents vote, this object holds:
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
    data_purity_score: float = Field(
        ...,
        ge=0,
        le=100,
        description="Confidence in the exactness of the market data given to the Den",
    )
    proceed: bool = Field(
        ...,
        description="True if consensus is strong enough to allow trading",
    )
    is_simulated: bool = Field(
        default=False,
        description="True if this consensus used any simulated/mock data",
    )
    tier: str = Field(
        default="civilian",
        description="The locked tier validation (observer, core, precision, institutional)",
    )
    required_threshold: float = Field(
        default=0.70,
        description="The matched threshold locked to this tier",
    )
    chairman_summary: Optional[str] = Field(
        default=None,
        description="Two sentence executive summary from the Chairman agent",
    )
    rejection_reason: Optional[str] = Field(
        default=None,
        description="If proceed is False, explains why (e.g. CALCULATION_MISMATCH)",
    )
    timestamp: datetime = Field(
        default_factory=lambda: datetime.now(timezone.utc),
        description="When the consensus was calculated (UTC)",
    )
    drawings: list[dict] = Field(
        default_factory=list,
        description="AI-generated drawing commands for the TradingView chart bridge",
    )
    panic_protocol_active: bool = Field(
        default=False,
        description="True if a systemic market failure or black swan was detected — emergency capital protection mode",
    )
    market_session: str = Field(
        default="Unknown",
        description="The global market session at the time of analysis (e.g. London, NY, Overlap)",
    )
    educational_explanation: str = Field(
        default="",
        description="A simple, Grade-4 English explanation of the chart analysis and drawings.",
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
    is_auto_execution: bool = Field(
        default=False,
        description="True if this order was generated by the Autopilot engine.",
    )
    tier: str = Field(
        default="civilian",
        description="The consensus tier this order was generated under. 'tiger' activates strict R:R enforcement.",
    )

class InternalTradeOrder(TradeOrder):
    """
    A TradeOrder that has been enriched with verified AI consensus scores
    by the backend. Passed securely to the Risk Microservice.
    """
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
    user_id: str
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
    expected_price: float = Field(
        default=0.0,
        description="The market price at the exact millisecond the Risk Engine approved the trade.",
    )
    use_virtual_stops: bool = Field(
        default=True,
        description="If true, SL/TP are withheld from the broker API and executed from memory.",
    )
    rejection_reason: Optional[str] = Field(
        default=None,
        description="If rejected, the exact reason why",
    )
    vetoing_agents: list[str] = Field(
        default_factory=list,
        description="List of agent names (e.g. ['TITAN', 'SAGE']) that vetoed this trade.",
    )
    timestamp: datetime = Field(
        default_factory=lambda: datetime.now(timezone.utc),
        description="When this decision was made (UTC)",
    )


# ──────────────────────────────────────────────
#  The Trader's Constitution — User-Defined Safety
# ──────────────────────────────────────────────

class ConstitutionRule(BaseModel):
    """
    A single mandate set by the trader or generated by the Auditor.
    """
    id: UUID | str = Field(default_factory=uuid4)
    name: str = Field(default="Legacy Rule", description="Short name, e.g., 'No Overtrading'")
    description: str = Field(..., description="Plain English description of the rule")
    rule_type: str = Field(
        default="custom",
        description="Type of rule: 'max_daily_trades', 'min_consensus', 'forbidden_hours', 'custom'"
    )
    parameter: float = Field(
        default=0.0,
        description="The numerical threshold (e.g., 3 trades, 80% consensus)"
    )
    condition_payload: dict = Field(
        default_factory=dict,
        description="JSON object holding dynamic autonomous rules (e.g. {'symbol': 'EUR/USD', 'max_spread_allowed': 3.5})"
    )
    is_active: bool = Field(default=True)
    created_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))

class AppConstitution(BaseModel):
    """
    The full document governing the trader's behavior. The Hard Risk Kernel
    will read this and physically prevent the trader from breaking it.
    """
    rules: list[ConstitutionRule] = Field(default_factory=list)
    daily_trades_count: int = Field(default=0, ge=0)
    last_reset_date: str = Field(default="")  # YYYY-MM-DD

# ──────────────────────────────────────────────
#  The Auditor — Post-Mortem Analysis
# ──────────────────────────────────────────────

class PostMortemRequest(BaseModel):
    trade_id: str
    symbol: str
    direction: Direction
    entry_price: float
    exit_price: float
    pnl: float
    user_notes: Optional[str] = None
    
class PostMortemResult(BaseModel):
    mistake_dna: str = Field(..., description="Categorized mistake e.g., 'FOMO', 'Revenge Trading', 'Bad Setup', 'Systematic Loss'")
    analysis: str = Field(..., description="Harsh, truth-telling analysis of the trade")
    suggested_rule: Optional[ConstitutionRule] = Field(
        default=None, 
        description="A proposed Constitution rule to prevent this from happening again."
    )

# ──────────────────────────────────────────────
#  The Autopilot — Auto-Execution Engine
# ──────────────────────────────────────────────

class AutopilotConfig(BaseModel):
    """
    The strict configuration for the Auto-Execution engine.
    Unlocked only when the user proves they are a safe trader.
    """
    enabled: bool = Field(
        default=False, 
        description="True if the user has unlocked and enabled Autopilot."
    )
    tier: str = Field(
        default="observer",
        description="The user's current subscription tier, cached for priority routing."
    )
    whitelisted_pairs: list[str] = Field(
        default_factory=list, 
        description="List of approved pairs, e.g. ['XAU/USD', 'EUR/USD']."
    )
    active_hours_start_utc: int = Field(
        default=0, ge=0, le=23, 
        description="Hour to start auto-trading (UTC)."
    )
    active_hours_end_utc: int = Field(
        default=23, ge=0, le=23, 
        description="Hour to stop auto-trading (UTC)."
    )
    preferred_lot_size: float = Field(
        default=0.01, ge=0.01, le=100.0,
        description="The user's preferred position size. Default 0.01 micro-lots."
    )
    active_allocations: dict[str, float] = Field(
        default_factory=dict, 
        description="Maps symbol to exact calculated lot size during master block execution."
    )
    max_concurrent_positions: int = Field(
        default=3, ge=1, le=10,
        description="Maximum number of simultaneous auto-trades allowed. Prevents overexposure."
    )
    assist_mode: bool = Field(
        default=False,
        description="If True, Sniper arms but waits for user confirmation before executing."
    )
    
    # Institutional Compounding Engine
    compounding_mode: Literal["OFF", "DYNAMIC SCALING", "INSTITUTIONAL COMPOUNDING"] = Field(
        default="OFF", 
        description="OFF, DYNAMIC SCALING, or INSTITUTIONAL COMPOUNDING"
    )
    predator_mode: bool = Field(
        default=False,
        description="ALPHA MODE: Switches from defense to predator after a win. Removes win-streak caps and scales risk aggressively."
    )
    simulated_equity: float = Field(
        default=100.0, 
        description="Starting simulated capital for compounding math."
    )
    peak_equity: float = Field(
        default=100.0, 
        description="Highest equity reached, used for drawdown calculation."
    )
    current_drawdown_pct: float = Field(
        default=0.0, 
        description="Drawdown from peak equity."
    )
    consecutive_wins: int = Field(
        default=0, 
        description="Win streak tracker."
    )
    consecutive_losses: int = Field(
        default=0, 
        description="Loss streak tracker."
    )
    
    # Eligibility & State Tracking
    last_losing_trade_timestamp: Optional[datetime] = Field(
        default=None, 
        description="Rolling 4-hour cooldown tracking."
    )
    max_daily_auto_trades: int = Field(
        default=2, ge=0, 
        description="Maximum number of daily auto-trades allowed per user."
    )
    daily_auto_trades_count: int = Field(
        default=0, ge=0, 
        description="Current count of daily trades."
    )
    last_trade_date: Optional[str] = Field(
        default=None,
        description="ISO date string (YYYY-MM-DD) of last auto-trade. Used to reset daily counter at midnight UTC."
    )
    weekly_auto_trades_count: int = Field(
        default=0, ge=0, 
        description="Max 5 per week."
    )
    frozen: bool = Field(
        default=False, 
        description="True if a broker API timeout occurred. Requires manual unfreeze."
    )
    open_auto_positions: list[str] = Field(
        default_factory=list,
        description="Symbols with currently open auto-execution positions. Prevents duplicate entries."
    )
    last_week_reset_date: Optional[str] = Field(
        default=None,
        description="ISO week string (YYYY-WXX) of last weekly counter reset. Used to reset weekly_auto_trades_count at week boundary."
    )


# ──────────────────────────────────────────────
#  MAM / Master Ledger Execution & Dark Pool
# ──────────────────────────────────────────────

class FirmInventory(BaseModel):
    """
    The Dark Pool internal ledger.
    Tracks 'leftover' fractional lots that the firm absorbs due to 
    rounding errors and dropped minimum-lot allocations.
    """
    symbol: str
    net_exposure_lots: float = Field(default=0.0, description="Total unhedged lots held by the firm.")
    last_updated: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))

class MasterTradeReceipt(BaseModel):
    """
    The receipt of a single block order placed by the AI on the broker.
    This replaces millions of individual broker API calls.
    """
    id: UUID = Field(default_factory=uuid4)
    symbol: str
    direction: Direction
    total_volume_lots: float
    fill_price: float
    fill_ratio: float = Field(default=1.0, description="successful_lots / requested_lots. Used for proportional distribution on partial fills.")
    profit_per_lot: float = Field(default=0.0, description="P&L in dollars per 1 standard lot. Used for ledger distribution.")
    status: str = Field(default="FILLED", description="FILLED, PARTIAL, or FAILED")
    is_closed: bool = Field(default=False, description="True if the position was closed before distribution completed")
    timestamp: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))

class LedgerDistributionTask(BaseModel):
    """
    Tracks the background job of distributing a MasterTradeReceipt
    to all eligible users without crashing the event loop.
    """
    receipt_id: UUID
    status: str = Field(default="PENDING", description="PENDING, PROCESSING, COMPLETED")
    total_eligible_users: int = 0
    users_processed: int = 0
    processed_user_ids: list[str] = Field(default_factory=list, description="Idempotency array to prevent double-booking on crash recovery")
    started_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
    completed_at: Optional[datetime] = None


class Watchlist(BaseModel):
    """
    A collection of symbols that the user is actively monitoring.
    Used for Phase 4: Smart Watchlists.
    """
    user_id: str
    symbols: list[str] = Field(default_factory=list)
    last_updated: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))


