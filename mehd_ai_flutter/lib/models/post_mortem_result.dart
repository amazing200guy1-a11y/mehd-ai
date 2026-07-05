class PostMortemResult {
  final String mistakeDna;
  final String analysis;
  final ConstitutionRule? suggestedRule;

  PostMortemResult({
    required this.mistakeDna,
    required this.analysis,
    this.suggestedRule,
  });

  factory PostMortemResult.fromJson(Map<String, dynamic> json) {
    return PostMortemResult(
      mistakeDna: json['mistake_dna'] ?? 'Undefined',
      analysis: json['analysis'] ?? 'No analysis provided.',
      suggestedRule: json['suggested_rule'] != null
          ? ConstitutionRule.fromJson(json['suggested_rule'])
          : null,
    );
  }
}

class ConstitutionRule {
  final String name;
  final String description;
  final String ruleType;
  final double parameter;

  ConstitutionRule({
    required this.name,
    required this.description,
    required this.ruleType,
    required this.parameter,
  });

  factory ConstitutionRule.fromJson(Map<String, dynamic> json) {
    return ConstitutionRule(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      ruleType: json['rule_type'] ?? '',
      parameter: (json['parameter'] ?? 0).toDouble(),
    );
  }
}
