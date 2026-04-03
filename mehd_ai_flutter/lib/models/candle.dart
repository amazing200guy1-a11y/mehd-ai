class Candle {
  final double open;
  final double high;
  final double low;
  final double close;
  final DateTime? timestamp;

  Candle({
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    this.timestamp,
  });

  bool get isBullish => close >= open;
  bool get isBearish => close < open;
  double get bodySize => (close - open).abs();
}
