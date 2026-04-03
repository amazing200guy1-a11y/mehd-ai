/// FIX 6: UserProfile — backwards-compatible with auth_service.dart
/// Now includes paper trading enforcement fields alongside existing auth fields.

enum BrokerType { demo, oanda, mt5, custom }

class UserProfile {
  final String userId;
  final String name;
  final String email;
  final BrokerType brokerType;
  final double riskPercent;
  final bool paperTradingMode;
  final bool onboardingComplete;
  final DateTime accountCreated;

  // FIX 6: Paper trading enforcement fields
  final int paperTradesCompleted;
  final bool legalAccepted;
  final double paperDrawdownPct;
  final bool liveTradingUnlocked;

  UserProfile({
    this.userId = '',
    this.name = '',
    this.email = '',
    this.brokerType = BrokerType.demo,
    this.riskPercent = 1.0,
    this.paperTradingMode = true,
    this.onboardingComplete = false,
    DateTime? accountCreated,
    this.paperTradesCompleted = 0,
    this.legalAccepted = false,
    this.paperDrawdownPct = 0.0,
    this.liveTradingUnlocked = false,
  }) : accountCreated = accountCreated ?? DateTime.now();

  /// Number of days since account creation
  int get accountAgeDays => DateTime.now().difference(accountCreated).inDays;

  /// Whether this user has cleared all requirements for live trading
  bool get isReadyForLive =>
      paperTradesCompleted >= 10 &&
      accountAgeDays >= 7 &&
      legalAccepted &&
      paperDrawdownPct < 10.0;

  /// Progress percentage toward live trading unlock
  double get progressPercent {
    double progress = 0;
    progress += (paperTradesCompleted.clamp(0, 10) / 10) * 40;
    progress += (accountAgeDays.clamp(0, 7) / 7) * 30;
    if (legalAccepted) progress += 15;
    if (paperDrawdownPct < 10.0) progress += 15;
    return progress.clamp(0, 100);
  }

  /// Human readable status line
  String get statusLine {
    if (isReadyForLive) return 'Ready for live trading!';
    final parts = <String>[];
    if (paperTradesCompleted < 10) parts.add('${10 - paperTradesCompleted} more paper trades');
    if (accountAgeDays < 7) parts.add('${7 - accountAgeDays} more days');
    if (!legalAccepted) parts.add('accept legal terms');
    if (paperDrawdownPct >= 10.0) parts.add('reduce paper drawdown');
    return 'Need: ${parts.join(', ')}';
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'name': name,
    'email': email,
    'brokerType': brokerType.name,
    'riskPercent': riskPercent,
    'paperTradingMode': paperTradingMode,
    'onboardingComplete': onboardingComplete,
    'accountCreated': accountCreated.toIso8601String(),
    'paperTradesCompleted': paperTradesCompleted,
    'legalAccepted': legalAccepted,
    'paperDrawdownPct': paperDrawdownPct,
    'liveTradingUnlocked': liveTradingUnlocked,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['userId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      brokerType: BrokerType.values.firstWhere(
        (e) => e.name == (json['brokerType'] as String? ?? 'demo'),
        orElse: () => BrokerType.demo,
      ),
      riskPercent: (json['riskPercent'] as num?)?.toDouble() ?? 1.0,
      paperTradingMode: json['paperTradingMode'] as bool? ?? true,
      onboardingComplete: json['onboardingComplete'] as bool? ?? false,
      accountCreated: json['accountCreated'] != null
          ? DateTime.tryParse(json['accountCreated'] as String) ?? DateTime.now()
          : DateTime.now(),
      paperTradesCompleted: json['paperTradesCompleted'] as int? ?? 0,
      legalAccepted: json['legalAccepted'] as bool? ?? false,
      paperDrawdownPct: (json['paperDrawdownPct'] as num?)?.toDouble() ?? 0.0,
      liveTradingUnlocked: json['liveTradingUnlocked'] as bool? ?? false,
    );
  }

  UserProfile copyWith({
    String? userId,
    String? name,
    String? email,
    BrokerType? brokerType,
    double? riskPercent,
    bool? paperTradingMode,
    bool? onboardingComplete,
    DateTime? accountCreated,
    int? paperTradesCompleted,
    bool? legalAccepted,
    double? paperDrawdownPct,
    bool? liveTradingUnlocked,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      brokerType: brokerType ?? this.brokerType,
      riskPercent: riskPercent ?? this.riskPercent,
      paperTradingMode: paperTradingMode ?? this.paperTradingMode,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      accountCreated: accountCreated ?? this.accountCreated,
      paperTradesCompleted: paperTradesCompleted ?? this.paperTradesCompleted,
      legalAccepted: legalAccepted ?? this.legalAccepted,
      paperDrawdownPct: paperDrawdownPct ?? this.paperDrawdownPct,
      liveTradingUnlocked: liveTradingUnlocked ?? this.liveTradingUnlocked,
    );
  }
}
