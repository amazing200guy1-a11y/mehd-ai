from datetime import datetime, timezone

def get_current_session() -> str:
    """
    Returns the name of the current major forex market session based on UTC time.
    
    Session Times (UTC):
    - Sydney: 22:00 - 07:00
    - Tokyo:  00:00 - 09:00
    - London: 08:00 - 16:00
    - NY:     13:00 - 21:00
    """
    now = datetime.now(timezone.utc)
    hour = now.hour
    
    # Check overlaps first (highest intensity)
    if 13 <= hour <= 16:
        return "London/NY Overlap"
    if 8 <= hour <= 9:
        return "Tokyo/London Overlap"
        
    # Single sessions
    if 8 <= hour < 16:
        return "London Session"
    if 13 <= hour < 21:
        return "New York Session"
    if 0 <= hour < 9:
        return "Tokyo Session"
    if hour >= 22 or hour < 7:
        return "Sydney Session"
        
    return "After Hours / Low Liquidity"
