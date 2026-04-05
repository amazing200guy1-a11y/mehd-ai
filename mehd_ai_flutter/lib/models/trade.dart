/// Trade model — represents a completed trade with PnL calculation.
/// Extracted from trade_history_item.dart for proper separation of concerns.

class Trade {
  final String symbol;
  final String direction;
  final double entryPrice;
  final double latestPrice;
  final DateTime timestamp;
  final double consensusScore;
  
  // Calculate PnL based on generic lots (10,000 units for this standard mock)
  double get pnl {
    final diff = latestPrice - entryPrice;
    if (direction == 'BUY') {
      return diff * 10000; 
    } else {
      return (entryPrice - latestPrice) * 10000;
    }
  }

  Trade({
    required this.symbol,
    required this.direction,
    required this.entryPrice,
    required this.latestPrice,
    required this.timestamp,
    required this.consensusScore,
  });
}
