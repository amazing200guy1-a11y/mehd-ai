/// FILE 4b — consensus_result.dart
///
/// Build Debrief:
/// This encapsulates the output from all 11 AI agents. We parse the 'votes' array
/// into strongly typed AIVote objects. This allows our AI Terminal widget to easily 
/// color-code the reasoning based on the 'direction' field without ugly string 
/// parsing everywhere in the widget tree.

class AIVote {
  final String modelName;
  final String snapshotId;
  final String direction; // BUY, SELL, HOLD
  final double confidence;
  final String reasoning;

  AIVote({
    required this.modelName,
    required this.snapshotId,
    required this.direction,
    required this.confidence,
    required this.reasoning,
  });

  factory AIVote.fromJson(Map<String, dynamic> json) {
    return AIVote(
      modelName: json['model_name'] as String,
      snapshotId: json['snapshot_id'] as String,
      direction: json['direction'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      reasoning: json['reasoning'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'model_name': modelName,
      'snapshot_id': snapshotId,
      'direction': direction,
      'confidence': confidence,
      'reasoning': reasoning,
    };
  }
}

class ConsensusResult {
  final List<AIVote> votes;
  final String finalDirection;
  final double consensusPercentage;
  final bool proceed;
  final String tier;
  final double requiredThreshold;
  final String? chairmanSummary;
  final String? rejectionReason;
  final bool panicProtocolActive;
  final DateTime timestamp;

  ConsensusResult({
    required this.votes,
    required this.finalDirection,
    required this.consensusPercentage,
    required this.proceed,
    this.tier = 'civilian',
    this.requiredThreshold = 0.70,
    this.chairmanSummary,
    this.rejectionReason,
    this.panicProtocolActive = false,
    required this.timestamp,
    Map<String, bool>? sovereignConditions,
  }) : sovereignConditions = sovereignConditions ?? const {};

  /// The 9 Sovereign Lock conditions — all must be true for SOVEREIGN tier.
  /// Keys: unanimity, spread_ok, volatility_ok, session_ok, drawdown_ok,
  ///        correlation_ok, news_clear, sentinel_clear, don_approved
  final Map<String, bool> sovereignConditions;

  /// Returns true only if ALL 9 sovereign conditions pass.
  bool get isSovereignLockAchieved =>
      tier == 'sovereign' &&
      proceed &&
      sovereignConditions.length >= 9 &&
      sovereignConditions.values.every((v) => v);

  factory ConsensusResult.fromJson(Map<String, dynamic> json) {
    final votesList = json['votes'] as List<dynamic>? ?? [];
    return ConsensusResult(
      votes: votesList.map((v) => AIVote.fromJson(v as Map<String, dynamic>)).toList(),
      finalDirection: json['final_direction'] as String,
      consensusPercentage: (json['consensus_percentage'] as num).toDouble(),
      proceed: json['proceed'] as bool,
      tier: json['tier'] as String? ?? 'civilian',
      requiredThreshold: (json['required_threshold'] as num?)?.toDouble() ?? 0.70,
      chairmanSummary: json['chairman_summary'] as String?,
      rejectionReason: json['rejection_reason'] as String?,
      panicProtocolActive: json['panic_protocol_active'] as bool? ?? false,
      timestamp: DateTime.parse(json['timestamp'] as String),
      sovereignConditions: (json['sovereign_conditions'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(k, v as bool),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'votes': votes.map((v) => v.toJson()).toList(),
      'final_direction': finalDirection,
      'consensus_percentage': consensusPercentage,
      'proceed': proceed,
      'tier': tier,
      'required_threshold': requiredThreshold,
      'chairman_summary': chairmanSummary,
      'rejection_reason': rejectionReason,
      'panic_protocol_active': panicProtocolActive,
      'timestamp': timestamp.toIso8601String(),
      'sovereign_conditions': sovereignConditions,
    };
  }
}
