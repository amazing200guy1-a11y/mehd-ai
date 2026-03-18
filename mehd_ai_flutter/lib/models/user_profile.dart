/// FILE 2 — user_profile.dart
///
/// Build Debrief:
/// This model mirrors the user document stored in Firestore. Every field is
/// carefully chosen: `riskPercent` is clamped to 0.1–1.0 in the constructor
/// itself, so even if tampered data arrives from the network, the model layer
/// enforces the cap before the UI or services ever see it.
///
/// `BrokerType` is an enum rather than a raw string because the app only
/// supports three connection modes. Enums give us exhaustive switch safety —
/// the compiler will warn us if we add a new broker type but forget to handle
/// it somewhere.
///
/// Why Firebase Auth was chosen: Firebase Auth provides battle-tested security
/// including password hashing (bcrypt), OAuth token management, email
/// verification, and abuse-prevention (rate limiting). Rolling our own auth
/// for a financial app would be dangerous — one mistake in password storage
/// and user accounts are compromised. Firebase handles this at Google-scale.

enum BrokerType { mt5, oanda, demo }

class UserProfile {
  final String userId;
  final String name;
  final String email;
  final BrokerType brokerType;
  final String? brokerLogin;     // Encrypted — never stored as plain text
  final String? brokerServer;    // MT5 server name
  final double riskPercent;      // 0.1 to 1.0 ONLY — hard-capped
  final bool paperTradingMode;
  final bool onboardingComplete;
  final DateTime createdAt;
  final int totalTrades;
  final double winRate;
  final DateTime joinedAt;

  UserProfile({
    required this.userId,
    required this.name,
    required this.email,
    this.brokerType = BrokerType.demo,
    this.brokerLogin,
    this.brokerServer,
    double riskPercent = 1.0,
    this.paperTradingMode = true,
    this.onboardingComplete = false,
    DateTime? createdAt,
    this.totalTrades = 0,
    this.winRate = 0.0,
    DateTime? joinedAt,
  })  : riskPercent = riskPercent.clamp(0.1, 1.0),
        createdAt = createdAt ?? DateTime.now(),
        joinedAt = joinedAt ?? DateTime.now();

  /// Creates a UserProfile from a Firestore document snapshot.
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['userId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      brokerType: _brokerTypeFromString(json['brokerType'] as String? ?? 'demo'),
      brokerLogin: json['brokerLogin'] as String?,
      brokerServer: json['brokerServer'] as String?,
      riskPercent: (json['riskPercent'] as num?)?.toDouble() ?? 1.0,
      paperTradingMode: json['paperTradingMode'] as bool? ?? true,
      onboardingComplete: json['onboardingComplete'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      totalTrades: json['totalTrades'] as int? ?? 0,
      winRate: (json['winRate'] as num?)?.toDouble() ?? 0.0,
      joinedAt: json['joinedAt'] != null
          ? DateTime.tryParse(json['joinedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Serializes to Firestore-ready JSON.
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'brokerType': brokerType.name,
      'brokerLogin': brokerLogin,
      'brokerServer': brokerServer,
      'riskPercent': riskPercent,
      'paperTradingMode': paperTradingMode,
      'onboardingComplete': onboardingComplete,
      'createdAt': createdAt.toIso8601String(),
      'totalTrades': totalTrades,
      'winRate': winRate,
      'joinedAt': joinedAt.toIso8601String(),
    };
  }

  /// Returns a copy with modified fields.
  UserProfile copyWith({
    String? name,
    BrokerType? brokerType,
    String? brokerLogin,
    String? brokerServer,
    double? riskPercent,
    bool? paperTradingMode,
    bool? onboardingComplete,
    int? totalTrades,
    double? winRate,
  }) {
    return UserProfile(
      userId: userId,
      name: name ?? this.name,
      email: email,
      brokerType: brokerType ?? this.brokerType,
      brokerLogin: brokerLogin ?? this.brokerLogin,
      brokerServer: brokerServer ?? this.brokerServer,
      riskPercent: riskPercent ?? this.riskPercent,
      paperTradingMode: paperTradingMode ?? this.paperTradingMode,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      createdAt: createdAt,
      totalTrades: totalTrades ?? this.totalTrades,
      winRate: winRate ?? this.winRate,
      joinedAt: joinedAt,
    );
  }

  static BrokerType _brokerTypeFromString(String value) {
    switch (value.toLowerCase()) {
      case 'mt5':
        return BrokerType.mt5;
      case 'oanda':
        return BrokerType.oanda;
      default:
        return BrokerType.demo;
    }
  }
}
