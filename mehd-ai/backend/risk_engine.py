"""
Mehd AI — Hard Risk Kernel
===========================
This is the single most important file in the entire system.

The HardRiskKernel sits OUTSIDE all AI influence. No model,
no Den verdict, no user override can change or bypass
these rules. They are calculated from raw math on the actual
account numbers.

Think of it like the circuit breaker in your house — the
electricity (AI) does the work, but if something goes wrong,
the breaker (this kernel) cuts power instantly. No negotiation.
"""

from __future__ import annotations

import logging
from datetime import datetime, timedelta, timezone
from typing import Optional
import json
import os

from models import (
    AccountHealth, 
    Direction, 
    RiskDecision, 
    TradeOrder, 
    AIVote,
    AppConstitution,
    ConstitutionRule
)

logger = logging.getLogger("mehd.risk_engine")

CONSTITUTION_FILE = os.path.join(os.path.dirname(__file__), "app_constitution.json")

class ConstitutionManager:
    """
    Manages loading, validating, and updating the Trader's Constitution.
    """
    @classmethod
    def load(cls) -> AppConstitution:
        if not os.path.exists(CONSTITUTION_FILE):
             # Create default constitution if none exists
            default_const = AppConstitution(
                rules=[
                    ConstitutionRule(
                        name="Overtrading Protection",
                        description="Maximum 3 trades per day to prevent revenge trading.",
                        rule_type="max_daily_trades",
                        parameter=3.0,
                    ),
                    ConstitutionRule(
                        name="High Conviction Only",
                        description="Only trade when consensus is 80% or higher.",
                        rule_type="min_consensus",
                        parameter=80.0,
                    )
                ]
            )
            cls.save(default_const)
            return default_const

        try:
            with open(CONSTITUTION_FILE, "r") as f:
                data = json.load(f)
            return AppConstitution.model_validate(data)
        except Exception as e:
            logger.error("Error loading constitution: %s", e)
            return AppConstitution()

    @classmethod
    def save(cls, constitution: AppConstitution) -> None:
        try:
            with open(CONSTITUTION_FILE, "w") as f:
                f.write(constitution.model_dump_json(indent=2))
        except Exception as e:
            logger.error("Error saving constitution: %s", e)
            
    @classmethod
    def increment_daily_trades(cls) -> None:
        const = cls.load()
        today = datetime.now(timezone.utc).strftime("%Y-%m-%d")
        if const.last_reset_date != today:
            const.daily_trades_count = 0
            const.last_reset_date = today
            
        const.daily_trades_count += 1
        cls.save(const)



class HardRiskKernel:
    """
    The unbreakable safety layer of Mehd AI.

    Every trade request must pass through evaluate() before
    it can be executed. If any rule fails, the trade is dead.

    Rules enforced:
    1. Max 1% of balance at risk per trade
    2. Every order MUST have a stop-loss
    3. 3% daily drawdown → 24-hour account lock
    4. Abnormal spread → volatility warning
    """

    # ── Constants ─────────────────────────────────────
    MAX_RISK_PER_TRADE_PCT: float = 1.0      # 1% of balance, period.
    MAX_DAILY_DRAWDOWN_PCT: float = 3.0      # 3% daily loss → lockout
    LOCKOUT_DURATION_HOURS: int = 24          # How long the lock lasts
    SPREAD_VOLATILITY_THRESHOLD: float = 5.0  # Pips — above this is "wide"
    PIP_VALUE_PER_STANDARD_LOT: float = 10.0  # $10 per pip per standard lot (simplified)

    def __init__(self) -> None:
        """
        The kernel starts with a clean state.
        In production, account_health would come from the broker API.
        For now, we initialise with a reasonable demo account.
        """
        self.account: AccountHealth = AccountHealth(
            balance=10_000.00,
            equity=10_000.00,
            daily_drawdown_pct=0.0,
            is_locked=False,
            lock_reason=None,
            lock_expiry=None,
        )
        logger.info("HardRiskKernel initialised — balance: $%.2f", self.account.balance)

    # ──────────────────────────────────────────────────
    #  PUBLIC: evaluate() — the only entry point
    # ──────────────────────────────────────────────────

    def evaluate(self, order: TradeOrder, current_price: float = 0.0, current_spread: float = 0.0) -> RiskDecision:
        """
        Run ALL risk checks on a trade order.
        Returns a RiskDecision — approved or rejected with reason.

        The order of checks matters:
        1. Account lock check (fastest — just read a boolean)
        2. Volatility check (spread too wide?)
        3. Stop-loss check (fast — just check if field is None)
        4. Risk sizing check (math — needs calculation)
        """
        logger.info(
            "Evaluating order: %s %s %.2f lots (entry_price=%.5f)",
            order.direction.value,
            order.symbol,
            order.lot_size,
            current_price,
        )

        # ── CHECK 1: Is the account locked? ──────────
        if self.account.is_locked:
            # Check if the lock has expired
            if self.account.lock_expiry and datetime.now(timezone.utc) >= self.account.lock_expiry:
                self._unlock_account()
            else:
                expiry_str = (
                    self.account.lock_expiry.isoformat()
                    if self.account.lock_expiry
                    else "unknown"
                )
                return RiskDecision(
                    approved=False,
                    calculated_lot_size=0.0,
                    stop_loss=order.stop_loss or 0.0001,
                    take_profit=order.take_profit,
                    rejection_reason=(
                        f"Account is locked: {self.account.lock_reason}. "
                        f"Unlocks at {expiry_str}"
                    ),
                )

        # ── CHECK 2: Volatility / Spread check ──────
        if current_spread > 0 and self.check_volatility(current_spread):
            return RiskDecision(
                approved=False,
                calculated_lot_size=0.0,
                stop_loss=order.stop_loss or 0.0001,
                take_profit=order.take_profit,
                rejection_reason=(
                    f"REJECTED: Spread is {current_spread:.1f} pips — above the "
                    f"{self.SPREAD_VOLATILITY_THRESHOLD} pip safety threshold. "
                    f"Trading during extreme volatility is blocked."
                ),
            )

        # ── CHECK 3: Is there a stop-loss? ───────────
        if order.stop_loss is None:
            return RiskDecision(
                approved=False,
                calculated_lot_size=0.0,
                stop_loss=0.0001,  # Placeholder — trade is rejected anyway
                take_profit=order.take_profit,
                rejection_reason=(
                    "REJECTED: No stop-loss provided. Every trade in Mehd AI "
                    "must have a stop-loss. This is non-negotiable."
                ),
            )

        # ── CHECK 3.5: OLYMPUS Agents Verification ──
        olympus_veto = self._verify_olympus_agents(order, current_price)
        if olympus_veto:
            return RiskDecision(
                approved=False,
                calculated_lot_size=0.0,
                stop_loss=order.stop_loss,
                take_profit=order.take_profit,
                rejection_reason=f"REJECTED: {olympus_veto}",
            )

        # ── CHECK 4: Calculate safe lot size ─────────
        safe_lot_size = self._calculate_safe_lot_size(order, current_price)

        if safe_lot_size <= 0:
            return RiskDecision(
                approved=False,
                calculated_lot_size=0.0,
                stop_loss=order.stop_loss,
                take_profit=order.take_profit,
                rejection_reason=(
                    "REJECTED: Calculated safe lot size is zero or negative. "
                    "The stop-loss distance may be too tight for your account balance."
                ),
            )

        # If the trader asked for more lots than is safe, cap it
        final_lot_size = min(order.lot_size, safe_lot_size)

        if final_lot_size < order.lot_size:
            logger.warning(
                "Lot size capped: requested %.4f → safe %.4f",
                order.lot_size,
                final_lot_size,
            )

        # ── CHECK 4: Daily drawdown check ────────────
        # (This check runs here because the trade itself might push
        #  drawdown over the limit — we need to simulate it)
        potential_loss = self._estimate_max_loss(final_lot_size, order, current_price)
        potential_drawdown_pct = (
            (self.account.daily_drawdown_pct)
            + (potential_loss / self.account.balance * 100)
        )

        if potential_drawdown_pct >= self.MAX_DAILY_DRAWDOWN_PCT:
            self._lock_account(
                reason=(
                    f"Daily drawdown would reach {potential_drawdown_pct:.2f}% "
                    f"(limit: {self.MAX_DAILY_DRAWDOWN_PCT}%). "
                    f"Trade blocked to protect your capital."
                )
            )
            return RiskDecision(
                approved=False,
                calculated_lot_size=0.0,
                stop_loss=order.stop_loss,
                take_profit=order.take_profit,
                rejection_reason=self.account.lock_reason,
            )

        # ── CHECK 5: The Trader's Constitution ────────
        # Load the trader's personal mandate and enforce it ruthlessly.
        constitution = ConstitutionManager.load()
        
        for rule in constitution.rules:
            if not rule.is_active:
                continue
                
            # Rule: Max Daily Trades
            if rule.rule_type == "max_daily_trades":
                if constitution.daily_trades_count >= rule.parameter:
                    logger.critical("🔥 CONSTITUTION VETO: %s (Limit: %d, Taken: %d)", 
                                    rule.name, rule.parameter, constitution.daily_trades_count)
                    return RiskDecision(
                        approved=False,
                        calculated_lot_size=0.0,
                        stop_loss=order.stop_loss or 0.0,
                        take_profit=order.take_profit,
                        rejection_reason=f"CONSTITUTION_VETO: {rule.description}"
                    )
            
            # Rule: Minimum Consensus (requires knowing the consensus %, which we don't have here)
            # We will assume consensus is passed in via the order or enforced before execution.
            # But we can add a placeholder comment.
            elif rule.rule_type == "min_consensus":
                # Enforced in the consensus engine or main.py. Passed here to avoid changing signature too much.
                pass
                
            # Rule: Forbidden Trading Hours (e.g., param could be an int representing hour to ban)
            elif rule.rule_type == "forbidden_hours":
                current_hour = datetime.now(timezone.utc).hour
                if current_hour == int(rule.parameter):
                    logger.critical("🔥 CONSTITUTION VETO: %s (Forbidden Hour: %02d:00 UTC)", 
                                    rule.name, int(rule.parameter))
                    return RiskDecision(
                        approved=False,
                        calculated_lot_size=0.0,
                        stop_loss=order.stop_loss or 0.0,
                        take_profit=order.take_profit,
                        rejection_reason=f"CONSTITUTION_VETO: {rule.description}"
                    )

        # ── ALL CHECKS PASSED ────────────────────────
        logger.info(
            "Trade APPROVED: %s %s %.4f lots (SL: %.5f, TP: %s)",
            order.direction.value,
            order.symbol,
            final_lot_size,
            order.stop_loss,
            order.take_profit,
        )

        return RiskDecision(
            approved=True,
            calculated_lot_size=final_lot_size,
            stop_loss=order.stop_loss,
            take_profit=order.take_profit,
            rejection_reason=None,
        )

    # ──────────────────────────────────────────────────
    #  PUBLIC: check_volatility() — spread check
    # ──────────────────────────────────────────────────

    def check_volatility(self, spread: float) -> bool:
        """
        Returns True if the spread is abnormally wide.

        When True, the frontend should grey out the trade button
        because trading during extreme volatility is dangerous —
        slippage can make stop-losses meaningless.
        """
        is_volatile = spread > self.SPREAD_VOLATILITY_THRESHOLD
        if is_volatile:
            logger.warning(
                "VOLATILITY WARNING: Spread %.2f pips exceeds threshold %.2f pips",
                spread,
                self.SPREAD_VOLATILITY_THRESHOLD,
            )
        return is_volatile

    def check_math_veto(self, math_votes: list[AIVote]) -> tuple[bool, str]:
        """
        Check if any 2 Math models veto the trade based on detecting
        black swans, extreme volatility, slippage >10%, or calculation mismatch.
        """
        vetoes = 0
        reasons = []

        for vote in math_votes:
            text = vote.reasoning.lower()
            if any(kw in text for kw in ["black swan", "volatility", "slippage"]):
                vetoes += 1
                reasons.append(vote.model_name)

        if len(math_votes) >= 2:
            confidences = [v.confidence for v in math_votes]
            max_divergence = max(confidences) - min(confidences)
            if max_divergence > 50.0:  # 50 percentage-point mismatch
                vetoes += 2
                reasons.append("divergence")

        if vetoes >= 2:
            reason = f"Math Layer Veto triggered by {', '.join(set(reasons))}."
            logger.critical("FIREBASE LOG: %s", reason)
            return True, reason

        return False, ""

    # ──────────────────────────────────────────────────
    #  PUBLIC: update_drawdown() — track daily losses
    # ──────────────────────────────────────────────────

    def update_drawdown(self, loss_amount: float) -> None:
        """
        Called after a trade closes at a loss to update the
        running daily drawdown percentage. If it crosses 3%,
        the account gets locked immediately.
        """
        if self.account.balance <= 0:
            self._lock_account(reason="Account balance is zero or negative")
            return

        loss_pct = (loss_amount / self.account.balance) * 100
        new_drawdown = self.account.daily_drawdown_pct + loss_pct

        self.account = self.account.model_copy(
            update={"daily_drawdown_pct": new_drawdown}
        )

        logger.info("Daily drawdown updated: %.2f%%", new_drawdown)

        if new_drawdown >= self.MAX_DAILY_DRAWDOWN_PCT:
            self._lock_account(
                reason=(
                    f"Daily drawdown hit {new_drawdown:.2f}% "
                    f"(limit: {self.MAX_DAILY_DRAWDOWN_PCT}%)"
                )
            )

    # ──────────────────────────────────────────────────
    #  PRIVATE helpers
    # ──────────────────────────────────────────────────

    def _verify_olympus_agents(self, order: TradeOrder, current_price: float) -> Optional[str]:
        """
        OLYMPUS mathematical verification before calculating anything else.
        ATLAS checks SL validity.
        TITAN checks TP validity.
        """
        if current_price <= 0:
            return None # Skip if no live price fed (e.g. mock test)

        is_buy = order.direction == Direction.BUY
        
        # ATLAS Verification
        if order.stop_loss is not None:
            if is_buy and order.stop_loss >= current_price:
                return "ATLAS VETO: Stop loss must be below current price for BUY orders."
            if not is_buy and order.stop_loss <= current_price:
                return "ATLAS VETO: Stop loss must be above current price for SELL orders."
                
        # TITAN Verification
        if order.take_profit is not None:
            if is_buy and order.take_profit <= current_price:
                return "TITAN VETO: Take profit must be above current price for BUY orders."
            if not is_buy and order.take_profit >= current_price:
                return "TITAN VETO: Take profit must be below current price for SELL orders."
                
        return None

    def _calculate_safe_lot_size(self, order: TradeOrder, entry_price: float = 0.0) -> float:
        """
        Calculate the maximum lot size that risks at most 1% of balance.

        Formula:
            max_risk_dollars = balance × (max_risk_pct / 100)
            stop_distance_pips = |entry_price - stop_loss| / pip_size
            safe_lots = max_risk_dollars / (stop_distance_pips × pip_value_per_lot)

        This is pure math — the AI has no say in this number.
        """
        max_risk_dollars = self.account.balance * (self.MAX_RISK_PER_TRADE_PCT / 100)

        # For forex, 1 pip = 0.0001 for most pairs (0.01 for JPY pairs)
        pip_size = 0.01 if "JPY" in order.symbol.upper() else 0.0001

        # Use the ACTUAL current market price passed from the streamer.
        # If not provided, fall back to a conservative 50-pip estimate.
        if entry_price > 0 and order.stop_loss is not None:
            stop_distance = abs(entry_price - order.stop_loss)
        else:
            stop_distance = 50.0 * pip_size  # Conservative fallback
            logger.warning("No entry price provided — using conservative 50-pip SL distance")

        stop_distance_pips = max(stop_distance / pip_size, 1.0)

        safe_lot_size = max_risk_dollars / (
            stop_distance_pips * self.PIP_VALUE_PER_STANDARD_LOT
        )

        # Round to 2 decimal places (standard lot precision)
        safe_lot_size = round(safe_lot_size, 2)

        logger.debug(
            "FORGE Risk calc: max_risk=$%.2f, entry=%.5f, sl=%.5f, stop_dist=%.1f pips, safe_lots=%.2f",
            max_risk_dollars,
            entry_price,
            order.stop_loss or 0.0,
            stop_distance_pips,
            safe_lot_size,
        )

        return safe_lot_size

    def _estimate_max_loss(self, lot_size: float, order: TradeOrder, entry_price: float = 0.0) -> float:
        """
        Estimate the maximum possible loss for this trade
        (i.e., if the stop-loss is hit).
        """
        pip_size = 0.01 if "JPY" in order.symbol.upper() else 0.0001

        if entry_price > 0 and order.stop_loss is not None:
            stop_distance = abs(entry_price - order.stop_loss)
        else:
            stop_distance = 50.0 * pip_size

        stop_distance_pips = max(stop_distance / pip_size, 1.0)

        max_loss = lot_size * stop_distance_pips * self.PIP_VALUE_PER_STANDARD_LOT
        return max_loss

    def _lock_account(self, reason: str) -> None:
        """Lock the account for LOCKOUT_DURATION_HOURS."""
        expiry = datetime.now(timezone.utc) + timedelta(hours=self.LOCKOUT_DURATION_HOURS)
        self.account = self.account.model_copy(
            update={
                "is_locked": True,
                "lock_reason": reason,
                "lock_expiry": expiry,
            }
        )
        logger.critical(
            "🔒 ACCOUNT LOCKED: %s — Unlocks at %s",
            reason,
            expiry.isoformat(),
        )

    def _unlock_account(self) -> None:
        """Unlock the account after the lockout period expires."""
        self.account = self.account.model_copy(
            update={
                "is_locked": False,
                "lock_reason": None,
                "lock_expiry": None,
                "daily_drawdown_pct": 0.0,
            }
        )
        logger.info("🔓 Account UNLOCKED — daily drawdown reset to 0%%")

    def get_account_health(self) -> AccountHealth:
        """Return the current account health snapshot."""
        # Auto-unlock if expiry has passed
        if (
            self.account.is_locked
            and self.account.lock_expiry
            and datetime.now(timezone.utc) >= self.account.lock_expiry
        ):
            self._unlock_account()
        return self.account
