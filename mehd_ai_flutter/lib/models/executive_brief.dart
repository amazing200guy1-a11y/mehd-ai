
class ExecutiveBrief {
  final String tradeId;
  final String symbol;
  final DateTime timestamp;
  final String finalVerdict;
  final String consensusScore;
  final Map<String, String> sentimentLayer;
  final Map<String, String> strategyLayer;
  final Map<String, String> mathLayer;
  final Map<String, String> riskVerification;
  final String decisionBasis;

  ExecutiveBrief({
    required this.tradeId,
    required this.symbol,
    required this.timestamp,
    required this.finalVerdict,
    required this.consensusScore,
    required this.sentimentLayer,
    required this.strategyLayer,
    required this.mathLayer,
    required this.riskVerification,
    required this.decisionBasis,
  });

  factory ExecutiveBrief.fromJson(Map<String, dynamic> json) {
    return ExecutiveBrief(
      tradeId: json['trade_id'] as String,
      symbol: json['symbol'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      finalVerdict: json['final_verdict'] as String,
      consensusScore: json['consensus_score'] as String,
      sentimentLayer: Map<String, String>.from(json['sentiment_layer'] ?? {}),
      strategyLayer: Map<String, String>.from(json['strategy_layer'] ?? {}),
      mathLayer: Map<String, String>.from(json['math_layer'] ?? {}),
      riskVerification: Map<String, String>.from(json['risk_verification'] ?? {}),
      decisionBasis: json['decision_basis'] as String,
    );
  }
}
