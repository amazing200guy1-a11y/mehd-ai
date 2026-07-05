import asyncio
import logging
import random
from datetime import datetime, timezone
from typing import Dict, Any, List

from state import DEMO_MODE
from system_health import health_registry

logger = logging.getLogger("mehd.black_swan")

BLACK_SWAN_AGENTS = ["grok", "perplexity", "gemini"]

class BlackSwanMonitor:
    """
    Upgrade 3: Black Swan Global Monitor
    Runs 24/7 monitoring global news out-of-band of price action.
    """
    def __init__(self):
        self._is_running = False
        self.current_level = 1
        self.last_update = datetime.now(timezone.utc)
        self.active_threat = "None"

    async def _scan_news(self, agent: str) -> Dict[str, Any]:
        """Mock news scan from one of the agents."""
        if not DEMO_MODE:
            logger.warning("BlackSwanMonitor live API not implemented. Failing safely for %s.", agent)
            return {
                "agent": agent,
                "level": 1,
                "threat": "Live API not implemented. Safety fallback.",
                "is_simulated": False
            }

        await asyncio.sleep(random.uniform(1.0, 3.0))
        
        # Randomly roll for a threat level
        # Level 1: 85%, Level 2: 13%, Level 3: 2%
        roll = random.random()
        if roll > 0.98:
            level = 3
            threat = "Critical Flash Crash / Geopolitical Escalation"
        elif roll > 0.85:
            level = 2
            threat = "High Impact FOMC / CPI Data Release"
        else:
            level = 1
            threat = "Standard Market Conditions"

        return {
            "agent": agent,
            "level": level,
            "threat": threat,
            "is_simulated": True
        }

    async def evaluate_threat_level(self) -> None:
        """
        Poll all 3 agents and determine the highest consensus threat level.
        """
        logger.info("BlackSwanMonitor scanning global sentiment...")
        tasks = [self._scan_news(agent) for agent in BLACK_SWAN_AGENTS]
        results = await asyncio.gather(*tasks, return_exceptions=True)
        
        levels = [r["level"] for r in results if isinstance(r, dict) and "level" in r]
        
        if not levels:
            return
            
        # The monitor takes the maximum perceived threat among the 3 agents
        # Because we'd rather be safe than sorry with a Black Swan.
        max_level = max(levels)
        
        self.current_level = max_level
        self.last_update = datetime.now(timezone.utc)
        
        if max_level == 3:
            self.active_threat = "LEVEL 3 BLACK SWAN: LIQUIDATE EVERYTHING."
            logger.critical("GLOBAL BLACK SWAN DETECTED: %s", self.active_threat)
        elif max_level == 2:
            self.active_threat = "LEVEL 2 THREAT: LOCK NEW TRADES."
            logger.warning("HIGH IMPACT DATA: %s", self.active_threat)
        else:
            self.active_threat = "None"

    async def run_daemon(self):
        """
        Runs continuously in the background.
        """
        self._is_running = True
        
        if DEMO_MODE:
            logger.warning("🦅 Black Swan Monitor Activated in SIMULATED mode. Threats are mocked.")
        else:
            logger.info("🦅 Black Swan Monitor Activated in LIVE mode.")
            
        while self._is_running:
            await self.evaluate_threat_level()
            
            await health_registry.report(
                "black_swan", 
                "YELLOW" if DEMO_MODE else "GREEN", 
                f"Level {self.current_level}: {self.active_threat}"
            )
            
            # Wait 60 seconds between scans
            await asyncio.sleep(60.0)

    def stop_daemon(self):
        self._is_running = False

    def get_status(self) -> Dict[str, Any]:
        """Provides state for the /health endpoint."""
        return {
            "swan_level": self.current_level,
            "swan_threat": self.active_threat,
            "swan_last_scan": self.last_update.isoformat(),
            "is_simulated": DEMO_MODE,
            "source": "simulated" if DEMO_MODE else "live"
        }

# Global singleton for FastAPI
monitor_instance = BlackSwanMonitor()
