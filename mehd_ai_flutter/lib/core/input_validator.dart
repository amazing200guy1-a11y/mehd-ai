/// Comprehensive input validation for all trade parameters.
/// Every field is validated BEFORE reaching the API or risk kernel.
/// Returns user-friendly error messages — never raw exceptions.

class InputValidator {
  /// Validate lot size: must be positive, max 100 lots
  static String? validateLotSize(double? lotSize) {
    if (lotSize == null || lotSize <= 0) return 'Lot size must be a positive number.';
    if (lotSize > 100) return 'Maximum lot size is 100.';
    if (lotSize < 0.01) return 'Minimum lot size is 0.01.';
    return null; // Valid
  }

  /// Validate stop loss relative to entry and direction
  static String? validateStopLoss({
    required double stopLoss,
    required double entryPrice,
    required String direction,
  }) {
    if (stopLoss <= 0) return 'Stop loss must be a positive price.';
    if (direction == 'BUY' && stopLoss >= entryPrice) {
      return 'Stop loss must be BELOW entry price for BUY orders.';
    }
    if (direction == 'SELL' && stopLoss <= entryPrice) {
      return 'Stop loss must be ABOVE entry price for SELL orders.';
    }
    return null;
  }

  /// Validate take profit relative to entry and direction
  static String? validateTakeProfit({
    required double takeProfit,
    required double entryPrice,
    required String direction,
  }) {
    if (takeProfit <= 0) return 'Take profit must be a positive price.';
    if (direction == 'BUY' && takeProfit <= entryPrice) {
      return 'Take profit must be ABOVE entry price for BUY orders.';
    }
    if (direction == 'SELL' && takeProfit >= entryPrice) {
      return 'Take profit must be BELOW entry price for SELL orders.';
    }
    return null;
  }

  /// Risk percent must be 0.1% to 1.0% — hardcoded institutional limit
  static String? validateRiskPercent(double? riskPct) {
    if (riskPct == null || riskPct < 0.1) return 'Minimum risk is 0.1%.';
    if (riskPct > 1.0) return 'Maximum risk is 1.0%. This is non-negotiable.';
    return null;
  }

  /// Symbol must exist in approved trading universe
  static String? validateSymbol(String? symbol) {
    if (symbol == null || symbol.isEmpty) return 'Symbol is required.';
    const approved = [
      'EURUSD', 'GBPUSD', 'USDJPY', 'AUDUSD', 'USDCAD',
      'NZDUSD', 'USDCHF', 'EURGBP', 'EURJPY', 'GBPJPY',
      'XAUUSD', 'XAGUSD', 'US30', 'NAS100', 'SPX500',
      'BTCUSD', 'ETHUSD',
    ];
    final clean = symbol.replaceAll('/', '').toUpperCase();
    if (!approved.contains(clean)) return '$symbol is not in the approved trading universe.';
    return null;
  }

  /// Account balance sanity check
  static String? validateBalance(double? balance) {
    if (balance == null || balance <= 0) return 'Account balance must be positive.';
    return null;
  }

  /// Validates all trade parameters at once. Returns null if ALL valid.
  static String? validateTradeOrder({
    required String symbol,
    required String direction,
    required double lotSize,
    required double entryPrice,
    required double stopLoss,
    double? takeProfit,
    double riskPercent = 1.0,
  }) {
    return validateSymbol(symbol) ??
        validateLotSize(lotSize) ??
        validateStopLoss(stopLoss: stopLoss, entryPrice: entryPrice, direction: direction) ??
        (takeProfit != null ? validateTakeProfit(takeProfit: takeProfit, entryPrice: entryPrice, direction: direction) : null) ??
        validateRiskPercent(riskPercent);
  }
}

/// Prevents duplicate trade execution within a cooldown window.
class DuplicateTradeGuard {
  static DateTime? _lastTradeTime;
  static String? _lastTradeKey;

  /// Returns true if this trade should be BLOCKED as a duplicate.
  static bool isDuplicate(String symbol, String direction) {
    final key = '${symbol}_$direction';
    final now = DateTime.now();
    
    if (_lastTradeKey == key && _lastTradeTime != null) {
      final elapsed = now.difference(_lastTradeTime!);
      if (elapsed.inSeconds < 5) return true; // Block — same trade within 5s
    }

    // Record this trade
    _lastTradeKey = key;
    _lastTradeTime = now;
    return false;
  }

  /// Force reset (e.g. after explicit user retry)
  static void reset() {
    _lastTradeKey = null;
    _lastTradeTime = null;
  }
}
