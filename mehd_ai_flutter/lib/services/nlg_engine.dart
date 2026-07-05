import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class NLGEngine {
  static final NLGEngine _instance = NLGEngine._internal();
  factory NLGEngine() => _instance;
  NLGEngine._internal();

  List<dynamic> _templates = [];
  final Random _random = Random();

  bool get isLoaded => _templates.isNotEmpty;

  /// Loads the 2,000 JSON templates from assets
  Future<void> loadTemplates() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/data/nlg_templates.json');
      _templates = jsonDecode(jsonString);
      debugPrint('✅ NLG Engine Loaded: ${_templates.length} templates ready.');
    } catch (e) {
      debugPrint('❌ Failed to load NLG templates: $e');
    }
  }

  /// Generates a highly unique Pulse Trading response based on market conditions.
  String generateResponse({
    required String direction, // 'BUY', 'SELL', 'HOLD'
    required String confidenceTier, // 'HIGH', 'MEDIUM', 'ANY'
  }) {
    if (_templates.isEmpty) {
      return "The Den is currently offline. Awaiting template injection.";
    }

    // Filter templates by direction
    List<dynamic> pool = _templates.where((t) => t['direction'] == direction).toList();
    
    // Fallback if direction pool is empty (shouldn't happen with 2000 templates)
    if (pool.isEmpty) pool = _templates;

    // Filter further by confidence if applicable (Hold is usually 'ANY')
    if (direction != 'HOLD') {
      var confidencePool = pool.where((t) => t['confidence_tier'] == confidenceTier).toList();
      if (confidencePool.isNotEmpty) {
        pool = confidencePool;
      }
    }

    // Select a random template from the filtered pool
    final selected = pool[_random.nextInt(pool.length)];
    return selected['text'] ?? "The agents are silent.";
  }
}
