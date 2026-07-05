import time
import random
from models import ConsensusResult, Direction

def generate_drawing_commands(
    symbol: str,
    analysis: ConsensusResult,
    candles: list[dict],
) -> list[dict]:
    """
    Translates the AI consensus results and recent market structure 
    into visual commands for the TradingView chart bridge.
    """
    commands = []
    
    if not candles:
        return commands

    # Find key levels from recent candles
    highs = [c.get('high', 0) for c in candles]
    lows = [c.get('low', 0) for c in candles]
    
    if not highs or not lows:
        return commands

    # 1. Primary Support & Resistance (Pivot Analysis)
    recent_highs = highs[-30:]
    recent_lows = lows[-30:]
    resistance = max(recent_highs)
    support = min(recent_lows)
    
    commands.append({
        'action': 'draw_horizontal_line',
        'id': 'resistance_primary',
        'price': resistance,
        'color': '#FF3B3B',
        'label': '▼ CORE RESISTANCE',
    })
    
    commands.append({
        'action': 'draw_horizontal_line',
        'id': 'support_primary',
        'price': support,
        'color': '#00FF88',
        'label': '▲ CORE SUPPORT',
    })
    
    # 2. Ghost Volume Zone (Supply/Demand)
    commands.append({
        'action': 'draw_zone',
        'id': 'supply_demand_zone',
        'price_top': support * 1.001,
        'price_bottom': support * 0.999,
        'color': '#00FF8822', # Transparent green
        'label': 'LIQUIDITY NODE',
    })
    
    # 3. AI Trend Corridor (Last 50 candles)
    if len(candles) >= 50:
        start_c = candles[-50]
        end_c = candles[-1]
        commands.append({
            'action': 'draw_trendline',
            'id': 'ai_trend_corridor',
            'p1_time': start_c['time'],
            'p1_price': start_c['close'],
            'p2_time': end_c['time'],
            'p2_price': end_c['close'],
            'color': '#3B82F6',
            'label': 'AI BIAS CORRIDOR',
        })

        # 4. Consensus Trade Arrow (Actionable Insight)
        if analysis.final_direction != Direction.HOLD:
            arrow_price = end_c['close']
            commands.append({
                'action': 'draw_arrow',
                'id': 'consensus_trigger',
                'time': end_c['time'],
                'price': arrow_price,
                'direction': analysis.final_direction.value,
                'label': f'AI {analysis.final_direction.value} TRIGGER ({analysis.consensus_percentage:.0f}%)',
            })
    
    return commands

def generate_mock_candles(base_price: float, count: int = 100) -> list[dict]:
    """Generates mock historical candles for drawing logic."""
    candles = []
    price = base_price * 0.995
    now = int(time.time())
    for i in range(count):
        open_p = price
        change = (random.random() - 0.48) * base_price * 0.003
        close_p = open_p + change
        high_p = max(open_p, close_p) + random.random() * base_price * 0.001
        low_p = min(open_p, close_p) - random.random() * base_price * 0.001
        
        candles.append({
            "time": now - ((count - i) * 3600),
            "open": round(open_p, 5),
            "high": round(high_p, 5),
            "low": round(low_p, 5),
            "close": round(close_p, 5),
            "is_simulated": True,
            "source": "mock"
        })
        price = close_p
    return candles

def validate_user_level(
    price: float,
    candles: list[dict],
) -> dict:
    """
    Validates a user-drawn horizontal level against market structure.
    Returns a dict with 'is_valid', 'label', and 'strength'.
    """
    if not candles:
        return {"is_valid": False, "label": "No data", "strength": 0, "color": "#444444"}

    highs = [c.get('high', 0) for c in candles]
    lows = [c.get('low', 0) for c in candles]
    
    # Check within tolerance (approx 0.1% for most major pairs)
    tolerance = price * 0.001
    
    # Check against recent peaks/troughs
    is_resistance = any(abs(price - h) < tolerance for h in highs[-50:])
    is_support = any(abs(price - l) < tolerance for l in lows[-50:])
    
    if is_resistance:
        return {
            "is_valid": True,
            "label": "AI VALIDATED RESISTANCE",
            "strength": 0.85,
            "color": "#FF3B3B"
        }
    if is_support:
        return {
            "is_valid": True,
            "label": "AI VALIDATED SUPPORT",
            "strength": 0.85,
            "color": "#00FF88"
        }
        
    return {
        "is_valid": False,
        "label": "UNVALIDATED ZONE",
        "strength": 0.2,
        "color": "#444444"
    }
