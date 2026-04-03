import 'dart:async';

/// High-performance TTL cache for API responses.
/// Eliminates duplicate network calls and provides instant cached data
/// while background refresh happens transparently.
class CacheService {
  static final CacheService _instance = CacheService._();
  factory CacheService() => _instance;
  CacheService._();

  final Map<String, _CacheEntry> _store = {};

  /// Gets a cached value, or calls [fetcher] if expired/missing.
  /// Returns cached data instantly if available, even if stale — then refreshes in background.
  Future<T> get<T>({
    required String key,
    required Future<T> Function() fetcher,
    required Duration ttl,
    bool backgroundRefresh = true,
  }) async {
    final entry = _store[key];

    if (entry != null && !entry.isExpired) {
      return entry.data as T;
    }

    // If stale but exists, return stale + refresh in background
    if (entry != null && backgroundRefresh) {
      _refreshInBackground(key, fetcher, ttl);
      return entry.data as T;
    }

    // No cache at all — must await
    final data = await fetcher();
    _store[key] = _CacheEntry(data: data, ttl: ttl);
    return data;
  }

  /// Stores data directly (for pre-caching).
  void put(String key, dynamic data, Duration ttl) {
    _store[key] = _CacheEntry(data: data, ttl: ttl);
  }

  /// Pre-cache popular symbols on startup.
  Future<void> preCacheSymbols(Future<dynamic> Function(String) fetcher) async {
    const symbols = ['EURUSD', 'XAUUSD', 'GBPUSD'];
    for (final symbol in symbols) {
      try {
        final data = await fetcher(symbol).timeout(const Duration(seconds: 5));
        put('analysis_$symbol', data, const Duration(minutes: 5));
      } catch (_) {
        // Silent — pre-cache is best-effort
      }
    }
  }

  /// Check if key exists and is fresh.
  bool has(String key) {
    final entry = _store[key];
    return entry != null && !entry.isExpired;
  }

  /// Invalidate a specific key.
  void invalidate(String key) => _store.remove(key);

  /// Clear entire cache.
  void clear() => _store.clear();

  /// Cache hit stats for performance metrics.
  final int _hits = 0;
  final int _misses = 0;
  double get hitRate => (_hits + _misses) == 0 ? 0 : _hits / (_hits + _misses) * 100;

  void _refreshInBackground<T>(String key, Future<T> Function() fetcher, Duration ttl) {
    fetcher().then((data) {
      _store[key] = _CacheEntry(data: data, ttl: ttl);
    }).catchError((_) {});
  }
}

class _CacheEntry {
  final dynamic data;
  final DateTime _createdAt;
  final Duration _ttl;

  _CacheEntry({required this.data, required Duration ttl})
      : _createdAt = DateTime.now(),
        _ttl = ttl;

  bool get isExpired => DateTime.now().difference(_createdAt) > _ttl;
}
