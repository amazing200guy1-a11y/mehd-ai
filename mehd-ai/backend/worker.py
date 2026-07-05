"""
Mehd AI — Dedicated Background Worker Process
==============================================
This script runs the background loops (Broadcaster, Autopilot, Stop Guardian, Cleanup, etc.)
independently of the FastAPI web server. This ensures CPU-bound trading tasks don't block
HTTP requests and live trade execution latency is minimized.
"""

import asyncio
import logging
import os
from dotenv import load_dotenv

# Load environmental variables
load_dotenv()

# Initialize logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s"
)
logger = logging.getLogger("mehd.worker")

# Import worker components
from broadcaster import broadcaster
from auto_execution_worker import auto_execution_worker
from cleanup_worker import cleanup_worker
from weekly_scan_worker import weekly_scan_worker
from position_health_worker import health_worker
from stop_guardian import black_swan
from data_streamer import streamer

async def main():
    logger.info("⚡ Starting Mehd AI Dedicated Background Workers...")

    # Start the data streamer (needed for market feeds)
    try:
        await streamer.start()
        logger.info("✓ Market Data Streamer started in worker thread")
    except Exception as e:
        logger.error("✗ Streamer startup error: %s", e)

    # 1. Start the Stop Guardian / Black Swan Monitor
    asyncio.create_task(black_swan.run_daemon())
    logger.info("✓ Black Swan Monitor Daemon active")

    # 2. Start the Broadcaster (Underground Research Daemon)
    await broadcaster.start()
    
    # Wire up push notifications for high-conviction signals in the worker thread
    try:
        from notification_service import send_high_conviction_alert
        async def _on_strong_signal(notification: dict):
            """Fires FCM alert when signal exceeds 80% confidence."""
            await send_high_conviction_alert(
                symbol=notification.get("symbol", ""),
                direction=notification.get("direction", ""),
                confidence=notification.get("confidence", 0),
                vote_count=notification.get("vote_count", 0),
            )
        broadcaster.set_notification_callback(_on_strong_signal)
        logger.info("✓ Push Notification dispatcher wired to Broadcaster")
    except Exception as e:
        logger.error("✗ Failed to wire notification callbacks: %s", e)

    logger.info("✓ Broadcaster daemon active")

    # 3. Start Execution and Health Workers
    auto_execution_worker.start()
    logger.info("✓ Autopilot Execution Worker active")
    
    cleanup_worker.start()
    logger.info("✓ Database Cleanup Worker active")
    
    weekly_scan_worker.start()
    logger.info("✓ Weekly Scan Worker active")
    
    health_worker.start()
    logger.info("✓ Position Health Worker active")

    logger.info("🚀 All Mehd AI background workers are running smoothly!")

    # Keep the worker process alive indefinitely
    while True:
        await asyncio.sleep(3600)

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        logger.info("Stopping all background workers due to user interrupt...")
