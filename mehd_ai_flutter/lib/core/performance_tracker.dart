
/// Tracks Den analysis performance for the War Room metrics panel.
/// Singleton — collects latency, error counts, and agent timing data
/// across the lifetime of the application session.

class PerformanceTracker {
  static final PerformanceTracker _instance = PerformanceTracker._();
  factory PerformanceTracker() => _instance;
  PerformanceTracker._();

  // ── Consensus Timing ───────────────────────────────────────────
  final List<double> _consensusTimes = [];
  int _totalAnalyses = 0;
  int _errorsToday = 0;
  DateTime? _lastPriceUpdate;

  void recordConsensusTime(double seconds) {
    _totalAnalyses++;
    _consensusTimes.add(seconds);
    if (_consensusTimes.length > 50) _consensusTimes.removeAt(0); // Rolling window
  }

  void recordError() => _errorsToday++;

  void recordPriceUpdate() => _lastPriceUpdate = DateTime.now();

  // ── Computed Metrics ───────────────────────────────────────────
  double get avgConsensusTime {
    if (_consensusTimes.isEmpty) return 0;
    final last10 = _consensusTimes.length > 10
        ? _consensusTimes.sublist(_consensusTimes.length - 10)
        : _consensusTimes;
    return last10.reduce((a, b) => a + b) / last10.length;
  }

  double get accuracy {
    if (_totalAnalyses == 0) return 100.0;
    return ((_totalAnalyses - _errorsToday) / _totalAnalyses * 100).clamp(0, 100);
  }

  int get errorsToday => _errorsToday;
  int get totalAnalyses => _totalAnalyses;

  Duration? get priceFeedAge {
    if (_lastPriceUpdate == null) return null;
    return DateTime.now().difference(_lastPriceUpdate!);
  }

  bool get isPriceStale {
    final age = priceFeedAge;
    if (age == null) return true;
    return age.inSeconds > 5;
  }

  /// War Room summary line
  String get warRoomSummary {
    final avg = avgConsensusTime.toStringAsFixed(1);
    final acc = accuracy.toStringAsFixed(1);
    return 'Den Performance: ${avg}s avg | $acc% accuracy | $_errorsToday errors today';
  }

  /// Reset daily counters (call at midnight or on app restart)
  void resetDaily() {
    _errorsToday = 0;
    _consensusTimes.clear();
    _totalAnalyses = 0;
  }
}
