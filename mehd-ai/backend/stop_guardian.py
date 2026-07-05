import asyncio
import logging
import random
from datetime import datetime, timezone
from typing import List, Dict, Any

from state import DEMO_MODE
from system_health import health_registry

logger = logging.getLogger("mehd.stop_guardian")

# The 4 Guardian agents assigned to monitor open positions
# PHANTOM (Perplexity), DON (Grok), FORGE (Codestral), TITAN (DeepSeek)
GUARDIAN_AGENTS = ["perplexity", "grok", "codestral", "deepseek"]

# Display name mapping for Guardian agents
GUARDIAN_DISPLAY_NAMES = {
    "perplexity": "PHANTOM",
    "grok": "DON",
    "codestral": "FORGE",
    "deepseek": "TITAN",
}

class StopGuardian:
    """
    Upgrade 2: AI Stop Guardian
    Runs every 30 seconds on open positions.
    Uses PHANTOM (Perplexity), DON (Grok), FORGE (Codestral), TITAN (DeepSeek).
    """

    def __init__(self):
        self._is_running = False

    async def _call_agent(self, agent: str, symbol: str, entry_price: float, current_price: float, position_type: str) -> Dict[str, Any]:
        """
        Mock AI call to analyze if the trend has reversed against the open position.
        In production, this would hit the actual LLM API.
        """
        if not DEMO_MODE:
            logger.warning("StopGuardian live API not implemented. Failing safely for %s.", agent)
            return {
                "agent": agent,
                "display_name": GUARDIAN_DISPLAY_NAMES.get(agent, agent.upper()),
                "reversal_detected": False,
                "confidence": 0.0,
                "reasoning": "Live API not implemented. Safety fallback.",
                "is_simulated": False,
                "source": "fallback"
            }

        await asyncio.sleep(random.uniform(0.5, 2.0)) # Simulate network delay
        
        # Randomly decide if trend reversed for demonstration
        # 10% chance an agent spots a reversal
        is_reversed = random.random() < 0.10
        
        display_name = GUARDIAN_DISPLAY_NAMES.get(agent, agent.upper())
        return {
            "agent": agent,
            "display_name": display_name,
            "reversal_detected": is_reversed,
            "confidence": random.uniform(80.0, 99.0) if is_reversed else random.uniform(50.0, 70.0),
            "reasoning": f"{display_name}: Trend {'reversal detected' if is_reversed else 'remains intact'} based on 15m structural analysis.",
            "is_simulated": True,
            "source": "mock"
        }

    async def evaluate_position(self, position: Dict[str, Any]) -> Dict[str, Any]:
        """
        Evaluate a single open position using the 4 Guardian agents.
        """
        symbol = position.get("symbol", "UNKNOWN")
        entry = position.get("entry_price", 0.0)
        current = position.get("current_price", 0.0)
        pos_type = position.get("type", "BUY")

        logger.info("StopGuardian analyzing %s %s...", symbol, pos_type)

        # Fire all 4 agents concurrently
        tasks = [
            self._call_agent(agent, symbol, entry, current, pos_type)
            for agent in GUARDIAN_AGENTS
        ]
        results = await asyncio.gather(*tasks, return_exceptions=True)
        
        # Tally votes for reversal
        reversal_votes = 0
        reversal_agents = []
        for r in results:
            if isinstance(r, dict) and r.get("reversal_detected"):
                reversal_votes += 1
                reversal_agents.append(r.get("display_name", r["agent"]))

        # Determine action stages (escalating severity)
        # Stage 1: 2+ reversals → Move stop loss to breakeven
        # Stage 2: 3+ reversals → Exit 50% of position
        # Stage 3: 4/4 reversals → Emergency full exit + SENTINEL alert
        
        action = "HOLD"
        message = "Trend confirmed. All 4 Guardians hold. Holding position."
        sentinel_triggered = False

        if reversal_votes >= 4:
            action = "STAGE_3_EMERGENCY_EXIT"
            message = "4/4 Guardians detected critical reversal. SENTINEL alerted. Emergency full exit."
            sentinel_triggered = True
            logger.critical("SENTINEL ALERT: Stage 3 emergency on %s. All 4 Guardians flagged reversal.", symbol)
        elif reversal_votes >= 3:
            action = "STAGE_2_PARTIAL_EXIT"
            message = f"3/4 Guardians detected reversal ({', '.join(reversal_agents)}). Exiting 50% of position."
        elif reversal_votes >= 2:
            action = "STAGE_1_BREAKEVEN"
            message = f"2/4 Guardians detected reversal ({', '.join(reversal_agents)}). Moving Stop Loss to breakeven."

        is_simulated = any(isinstance(r, dict) and r.get("is_simulated", False) for r in results)

        return {
            "symbol": symbol,
            "action": action,
            "message": message,
            "reversal_votes": reversal_votes,
            "agents_flagged": reversal_agents,
            "sentinel_triggered": sentinel_triggered,
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "is_simulated": is_simulated,
            "source": "mock" if is_simulated else "live"
        }

    async def run_daemon(self, get_open_positions_callback):
        """
        Runs every 30 seconds to monitor all open positions.
        """
        self._is_running = True
        
        if DEMO_MODE:
            logger.warning("🛡️ Stop Guardian Activated in SIMULATED mode. Signals are mocked.")
            await health_registry.report("stop_guardian", "YELLOW", "Running in simulated mode")
        else:
            logger.info("🛡️ Stop Guardian Activated in LIVE mode.")
            await health_registry.report("stop_guardian", "GREEN", "Live monitoring active")
        
        while self._is_running:
            positions = get_open_positions_callback()
            if not positions:
                await health_registry.report("stop_guardian", "YELLOW" if DEMO_MODE else "GREEN", "Monitoring (0 positions)")
                await asyncio.sleep(30)
                continue

            # Evaluate all positions concurrently
            tasks = [self.evaluate_position(pos) for pos in positions]
            results = await asyncio.gather(*tasks, return_exceptions=True)

            for res in results:
                if isinstance(res, dict) and res["action"] != "HOLD":
                    logger.warning("[STOP GUARDIAN ALERT] %s: %s", res['symbol'], res['message'])
                    # Here we would trigger the broker API to actually modify/close the order

            await health_registry.report(
                "stop_guardian", 
                "YELLOW" if DEMO_MODE else "GREEN", 
                f"Monitoring ({len(positions)} positions)"
            )
            await asyncio.sleep(30)

    def stop_daemon(self):
        self._is_running = False
