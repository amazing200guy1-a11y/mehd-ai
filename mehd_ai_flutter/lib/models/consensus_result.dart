/// FILE 4b — consensus_result.dart
///
/// Build Debrief:
/// This encapsulates the output from all 9 AI models. We parse the 'votes' array
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
  final String? rejectionReason;
  final DateTime timestamp;

  ConsensusResult({
    required this.votes,
    required this.finalDirection,
    required this.consensusPercentage,
    required this.proceed,
    this.rejectionReason,
    required this.timestamp,
  });

  factory ConsensusResult.fromJson(Map<String, dynamic> json) {
    final votesList = json['votes'] as List<dynamic>? ?? [];
    return ConsensusResult(
      votes: votesList.map((v) => AIVote.fromJson(v as Map<String, dynamic>)).toList(),
      finalDirection: json['final_direction'] as String,
      consensusPercentage: (json['consensus_percentage'] as num).toDouble(),
      proceed: json['proceed'] as bool,
      rejectionReason: json['rejection_reason'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'votes': votes.map((v) => v.toJson()).toList(),
      'final_direction': finalDirection,
      'consensus_percentage': consensusPercentage,
      'proceed': proceed,
      'rejection_reason': rejectionReason,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
