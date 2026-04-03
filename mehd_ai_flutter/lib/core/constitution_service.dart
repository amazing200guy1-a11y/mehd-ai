import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mehd_ai_flutter/core/constants.dart';

class ConstitutionRule {
  final String id;
  final String name;
  final String description;
  final String ruleType;
  final double parameter;
  final bool isActive;

  ConstitutionRule({
    required this.id,
    required this.name,
    required this.description,
    required this.ruleType,
    required this.parameter,
    required this.isActive,
  });

  factory ConstitutionRule.fromJson(Map<String, dynamic> json) {
    return ConstitutionRule(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      ruleType: json['rule_type'] ?? '',
      parameter: (json['parameter'] ?? 0).toDouble(),
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'rule_type': ruleType,
        'parameter': parameter,
        'is_active': isActive,
      };
}

class AppConstitution {
  final List<ConstitutionRule> rules;
  final int dailyTradesCount;
  final String lastResetDate;

  AppConstitution({
    required this.rules,
    required this.dailyTradesCount,
    required this.lastResetDate,
  });

  factory AppConstitution.fromJson(Map<String, dynamic> json) {
    var rulesList = json['rules'] as List? ?? [];
    return AppConstitution(
      rules: rulesList.map((r) => ConstitutionRule.fromJson(r)).toList(),
      dailyTradesCount: json['daily_trades_count'] ?? 0,
      lastResetDate: json['last_reset_date'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'rules': rules.map((r) => r.toJson()).toList(),
        'daily_trades_count': dailyTradesCount,
        'last_reset_date': lastResetDate,
      };
}

class ConstitutionService {
  final String baseUrl = AppConstants.baseUrl;

  Future<AppConstitution> getConstitution() async {
    final response = await http.get(Uri.parse('$baseUrl/constitution'));
    if (response.statusCode == 200) {
      return AppConstitution.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load Constitution');
    }
  }

  Future<AppConstitution> updateConstitution(AppConstitution constitution) async {
    final response = await http.post(
      Uri.parse('$baseUrl/constitution'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(constitution.toJson()),
    );
    if (response.statusCode == 200) {
      return AppConstitution.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update Constitution');
    }
  }
}
