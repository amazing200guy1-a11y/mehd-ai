import 'package:flutter/material.dart';
import 'package:mehd_ai_flutter/core/theme.dart';

/// THE DEN IDENTITY — MEHD AI Proprietary Agent Mapping
/// Maps backend model IDs to Mehd AI's branded 11-agent architecture.

class AgentIdentity {
  final String id;
  final String displayName;
  final String layer;
  final String personality;
  final Color nodeColor;
  final IconData icon;

  const AgentIdentity({
    required this.id,
    required this.displayName,
    required this.layer,
    required this.personality,
    required this.nodeColor,
    required this.icon,
  });
}

class DenIdentity {
  static const agents = {
    // ---- THE UNDERWORLD (Intelligence Layer) ----
    'don': AgentIdentity(
      id: 'don',
      displayName: 'DON',
      layer: 'THE UNDERWORLD',
      personality: 'Street Intelligence Agent',
      nodeColor: Color(0xFF6A0DAD), // Dark purple
      icon: Icons.public,
    ),
    'phantom': AgentIdentity(
      id: 'phantom',
      displayName: 'PHANTOM',
      layer: 'THE UNDERWORLD',
      personality: 'Verification & Stealth Agent',
      nodeColor: Color(0xFF6A0DAD), // Dark purple
      icon: Icons.library_books,
    ),
    'oracle': AgentIdentity(
      id: 'oracle',
      displayName: 'ORACLE',
      layer: 'THE UNDERWORLD',
      personality: 'Prediction & Vision Agent',
      nodeColor: Color(0xFF6A0DAD), // Dark purple
      icon: Icons.auto_graph,
    ),

    // ---- THE EMPIRE (Strategy Layer) ----
    'caesar': AgentIdentity(
      id: 'caesar',
      displayName: 'CAESAR',
      layer: 'THE EMPIRE',
      personality: 'Chief Strategy Agent',
      nodeColor: MehdAiTheme.gold, // Deep gold
      icon: Icons.bolt,
    ),
    'sage': AgentIdentity(
      id: 'sage',
      displayName: 'SAGE',
      layer: 'THE EMPIRE',
      personality: 'Risk & Wisdom Agent',
      nodeColor: MehdAiTheme.gold, // Deep gold
      icon: Icons.psychology,
    ),
    'guardian': AgentIdentity(
      id: 'guardian',
      displayName: 'GUARDIAN',
      layer: 'THE EMPIRE',
      personality: 'Capital Protection Agent',
      nodeColor: MehdAiTheme.gold, // Deep gold
      icon: Icons.all_inclusive,
    ),

    // ---- OLYMPUS (Mathematical Layer) ----
    'titan': AgentIdentity(
      id: 'titan',
      displayName: 'TITAN',
      layer: 'OLYMPUS',
      personality: 'Backtesting & Power Agent',
      nodeColor: MehdAiTheme.blue, // Electric blue
      icon: Icons.radar,
    ),
    'atlas': AgentIdentity(
      id: 'atlas',
      displayName: 'ATLAS',
      layer: 'OLYMPUS',
      personality: 'Quantitative Calculation Agent',
      nodeColor: MehdAiTheme.blue, // Electric blue
      icon: Icons.hub,
    ),
    'forge': AgentIdentity(
      id: 'forge',
      displayName: 'FORGE',
      layer: 'OLYMPUS',
      personality: 'Execution & Code Agent',
      nodeColor: MehdAiTheme.blue, // Electric blue
      icon: Icons.data_object,
    ),

    // ---- SUPREME & GUARDIAN ----
    'the don': AgentIdentity(
      id: 'the don',
      displayName: 'THE DON',
      layer: 'SUPREME',
      personality: 'Supreme Aggregator',
      nodeColor: Colors.white,
      icon: Icons.account_balance,
    ),
    'sentinel': AgentIdentity(
      id: 'sentinel',
      displayName: 'SENTINEL',
      layer: 'GUARDIAN',
      personality: 'Anti-Hallucination Guardian',
      nodeColor: Colors.redAccent,
      icon: Icons.remove_red_eye,
    ),
    'vanguard': AgentIdentity(
      id: 'vanguard',
      displayName: 'VANGUARD',
      layer: 'OLYMPUS',
      personality: 'Forward Reconnaissance Agent',
      nodeColor: MehdAiTheme.blue,
      icon: Icons.explore,
    ),
  };

  static AgentIdentity getIdentity(String rawModelName) {
    final key = rawModelName.toLowerCase();
    
    // Internal Mapping for raw model names to branded Den identities
    final Map<String, String> modelToAgent = {
      'grok': 'don',
      'perplexity': 'phantom',
      'gemini': 'oracle',
      'gpt-4': 'caesar',
      'claude': 'sage',
      'llama': 'guardian',
      'deepseek': 'titan',
      'openai-o3': 'atlas',
      'codestral': 'forge',
      'chairman': 'the don',
    };

    final agentId = modelToAgent[key] ?? key;
    return agents[agentId] ??
        AgentIdentity(
          id: agentId,
          displayName: agentId.toUpperCase(),
          layer: 'UNKNOWN',
          personality: 'External Agent',
          nodeColor: Colors.grey,
          icon: Icons.device_unknown,
        );
  }

}
