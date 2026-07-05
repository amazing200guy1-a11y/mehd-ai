import 'package:flutter/material.dart';

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
    // ---- THE RESEARCH (Intelligence Layer) ----
    'don': AgentIdentity(
      id: 'don',
      displayName: 'DON',
      layer: 'THE RESEARCH',
      personality: 'Street Intelligence Agent',
      nodeColor: Color(0xFF5C7A99), // Muted slate-blue
      icon: Icons.public,
    ),
    'phantom': AgentIdentity(
      id: 'phantom',
      displayName: 'PHANTOM',
      layer: 'THE RESEARCH',
      personality: 'Verification & Stealth Agent',
      nodeColor: Color(0xFF5C7A99), // Muted slate-blue
      icon: Icons.library_books,
    ),
    'oracle': AgentIdentity(
      id: 'oracle',
      displayName: 'ORACLE',
      layer: 'THE RESEARCH',
      personality: 'Prediction & Vision Agent',
      nodeColor: Color(0xFF5C7A99), // Muted slate-blue
      icon: Icons.auto_graph,
    ),

    // ---- THE STRATEGY (Strategy Layer) ----
    'caesar': AgentIdentity(
      id: 'caesar',
      displayName: 'CAESAR',
      layer: 'THE STRATEGY',
      personality: 'Chief Strategy Agent',
      nodeColor: Color(0xFF8A9BB0), // Muted silver-slate
      icon: Icons.bolt,
    ),
    'sage': AgentIdentity(
      id: 'sage',
      displayName: 'SAGE',
      layer: 'THE STRATEGY',
      personality: 'Risk & Wisdom Agent',
      nodeColor: Color(0xFF8A9BB0), // Muted silver-slate
      icon: Icons.psychology,
    ),
    'guardian': AgentIdentity(
      id: 'guardian',
      displayName: 'GUARDIAN',
      layer: 'THE STRATEGY',
      personality: 'Capital Protection Agent',
      nodeColor: Color(0xFF8A9BB0), // Muted silver-slate
      icon: Icons.all_inclusive,
    ),

    // ---- OLYMPUS (Mathematical Layer) ----
    'titan': AgentIdentity(
      id: 'titan',
      displayName: 'TITAN',
      layer: 'OLYMPUS',
      personality: 'Backtesting & Power Agent',
      nodeColor: Color(0xFF4DA8A0), // Dim teal-cyan
      icon: Icons.radar,
    ),
    'atlas': AgentIdentity(
      id: 'atlas',
      displayName: 'ATLAS',
      layer: 'OLYMPUS',
      personality: 'Quantitative Calculation Agent',
      nodeColor: Color(0xFF4DA8A0), // Dim teal-cyan
      icon: Icons.hub,
    ),
    'forge': AgentIdentity(
      id: 'forge',
      displayName: 'FORGE',
      layer: 'OLYMPUS',
      personality: 'Execution & Code Agent',
      nodeColor: Color(0xFF4DA8A0), // Dim teal-cyan
      icon: Icons.data_object,
    ),

    // ---- SUPREME & GUARDIAN ----
    'the don': AgentIdentity(
      id: 'the don',
      displayName: 'THE DON',
      layer: 'SUPREME',
      personality: 'Supreme Aggregator',
      nodeColor: Color(0xFFC8D6E5), // Soft white-blue
      icon: Icons.account_balance,
    ),
    'sentinel': AgentIdentity(
      id: 'sentinel',
      displayName: 'SENTINEL',
      layer: 'GUARDIAN',
      personality: 'Anti-Hallucination Guardian',
      nodeColor: Color(0xFFB08D57), // Muted amber
      icon: Icons.remove_red_eye,
    ),
    'vanguard': AgentIdentity(
      id: 'vanguard',
      displayName: 'VANGUARD',
      layer: 'OLYMPUS',
      personality: 'Forward Reconnaissance Agent',
      nodeColor: Color(0xFF4DA8A0), // Dim teal-cyan
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
