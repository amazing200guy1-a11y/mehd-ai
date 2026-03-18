/// FILE 4a — market_snapshot.dart
///
/// Build Debrief:
/// Strict typing on the frontend. This model mirrors exactly what the FastAPI 
/// backend sends. By parsing raw JSON into this Dart object immediately at the 
/// network boundary, the rest of our app never has to guess if 'bid' is a string 
/// or a double. It prevents the UI from freezing due to a TypeError.

class MarketSnapshot {
  final String id;
  final String symbol;
  final double bid;
  final double ask;
  final double spread;
  final DateTime timestamp;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;

  MarketSnapshot({
    required this.id,
    required this.symbol,
    required this.bid,
    required this.ask,
    required this.spread,
    required this.timestamp,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  factory MarketSnapshot.fromJson(Map<String, dynamic> json) {
    return MarketSnapshot(
      id: json['id'] as String,
      symbol: json['symbol'] as String,
      bid: (json['bid'] as num).toDouble(),
      ask: (json['ask'] as num).toDouble(),
      spread: (json['spread'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      open: (json['open'] as num).toDouble(),
      high: (json['high'] as num).toDouble(),
      low: (json['low'] as num).toDouble(),
      close: (json['close'] as num).toDouble(),
      volume: (json['volume'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'symbol': symbol,
      'bid': bid,
      'ask': ask,
      'spread': spread,
      'timestamp': timestamp.toIso8601String(),
      'open': open,
      'high': high,
      'low': low,
      'close': close,
      'volume': volume,
    };
  }
}
