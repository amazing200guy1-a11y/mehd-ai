/// FIX 1 — MarketSnapshot with data freshness fields
/// Mirrors backend exactly. data_age_ms, data_source, is_live, latency_warning
/// tell the frontend exactly how trustworthy the current price is.

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
  final int? timestampNs;
  final String? orderBookWalls;

  // FIX 1: Data Freshness
  final int dataAgeMs;
  final String dataSource;
  final bool isLive;
  final bool latencyWarning;

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
    this.timestampNs,
    this.orderBookWalls,
    this.dataAgeMs = 0,
    this.dataSource = 'mock',
    this.isLive = false,
    this.latencyWarning = false,
  });

  /// True if data is under 5 seconds old
  bool get isFresh => dataAgeMs < 5000;

  /// True if data is stale (over 5 seconds) — should lock trading
  bool get isStale => dataAgeMs >= 5000;

  /// Human readable staleness label
  String get freshnessLabel {
    if (dataAgeMs < 1000) return 'LIVE';
    if (dataAgeMs < 5000) return 'DELAYED ${(dataAgeMs / 1000).toStringAsFixed(0)}s';
    return 'STALE — Do not trade';
  }

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
      timestampNs: json['timestamp_ns'] as int?,
      orderBookWalls: json['order_book_walls'] as String?,
      dataAgeMs: (json['data_age_ms'] as num?)?.toInt() ?? 0,
      dataSource: json['data_source'] as String? ?? 'mock',
      isLive: json['is_live'] as bool? ?? false,
      latencyWarning: json['latency_warning'] as bool? ?? false,
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
      'timestamp_ns': timestampNs,
      'order_book_walls': orderBookWalls,
      'data_age_ms': dataAgeMs,
      'data_source': dataSource,
      'is_live': isLive,
      'latency_warning': latencyWarning,
    };
  }
}
