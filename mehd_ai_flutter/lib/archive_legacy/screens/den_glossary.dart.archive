import 'package:flutter/material.dart';
import 'package:mehd_ai_flutter/core/theme.dart';
import 'package:mehd_ai_flutter/core/den_identity.dart';

class DenGlossary extends StatelessWidget {
  const DenGlossary({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MehdAiTheme.bgPrimary,
      appBar: AppBar(
        title: Text('THE DEN GLOSSARY', style: MehdAiTheme.headingStyle),
        backgroundColor: MehdAiTheme.bgSecondary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        children: [
          Text(
            'THE 11 AGENTS OF THE DEN',
            style: MehdAiTheme.headingStyle.copyWith(color: MehdAiTheme.gold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'Mehd AI’s proprietary Consensus-Verified Trading™ infrastructure is powered by 11 distinct personas across 4 layers.',
            style: MehdAiTheme.labelStyle,
          ),
          const SizedBox(height: 24),
          _buildLayerSection('THE UNDERWORLD', ['don', 'phantom', 'oracle']),
          _buildLayerSection('THE EMPIRE', ['caesar', 'sage', 'guardian']),
          _buildLayerSection('OLYMPUS', ['titan', 'atlas', 'forge']),
          _buildLayerSection('SUPREME COMMAND', ['the don', 'sentinel']),

        ],
      ),
    );
  }

  Widget _buildLayerSection(String layerName, List<String> agentIds) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(layerName, style: MehdAiTheme.headingStyle.copyWith(color: MehdAiTheme.blue)),
        const Divider(color: MehdAiTheme.borderColor),
        const SizedBox(height: 8),
        ...agentIds.map((id) => _buildAgentRow(DenIdentity.getIdentity(id))),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildAgentRow(AgentIdentity agent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: agent.nodeColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(agent.icon, color: agent.nodeColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(agent.displayName, style: MehdAiTheme.headingStyle.copyWith(color: agent.nodeColor)),
                const SizedBox(height: 2),
                Text(agent.personality, style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.textSecondary, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
