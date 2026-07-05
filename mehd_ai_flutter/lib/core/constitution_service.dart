import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
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

  Future<Map<String, String>> _getHeaders([Map<String, String>? extra]) async {
    final user = FirebaseAuth.instance.currentUser;
    final token = user != null ? await user.getIdToken() : null;
    final h = <String, String>{};
    if (token != null) h['Authorization'] = 'Bearer $token';
    if (extra != null) h.addAll(extra);
    return h;
  }

  Future<AppConstitution> getConstitution() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('You must be signed in to view your Constitution.');
    final response = await http.get(
      Uri.parse('$baseUrl/constitution'),
      headers: await _getHeaders(),
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw Exception('Request timed out. Please check your connection.'),
    );
    if (response.statusCode == 200) {
      return AppConstitution.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load your trading rules. Please try again.');
    }
  }

  Future<AppConstitution> updateConstitution(AppConstitution constitution) async {
    final response = await http.post(
      Uri.parse('$baseUrl/constitution'),
      headers: await _getHeaders({'Content-Type': 'application/json'}),
      body: jsonEncode(constitution.toJson()),
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw Exception('Request timed out. Please check your connection.'),
    );
    if (response.statusCode == 200) {
      return AppConstitution.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to save your changes. Please try again.');
    }
  }
}
