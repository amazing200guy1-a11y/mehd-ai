import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mehd_ai_flutter/core/theme.dart';

/// Shows a quick-reference help modal explaining core Den concepts.
void showDenHelpModal(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => const DenHelpModal(),
  );
}

class DenHelpModal extends StatelessWidget {
  const DenHelpModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: 500,
            constraints: const BoxConstraints(maxHeight: 600),
            decoration: BoxDecoration(
              color: const Color(0xFF080808).withOpacity(0.92),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: MehdAiTheme.blue.withOpacity(0.25),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: MehdAiTheme.blue.withOpacity(0.15),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: MehdAiTheme.blue.withOpacity(0.1),
                        ),
                        child: const Icon(Icons.help_outline, color: MehdAiTheme.blue, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('THE DEN — QUICK REFERENCE',
                            style: MehdAiTheme.headingStyle.copyWith(fontSize: 14, letterSpacing: 2)),
                          const SizedBox(height: 2),
                          Text('Mehd AI Intelligence System',
                            style: MehdAiTheme.labelStyle.copyWith(color: MehdAiTheme.textSecondary)),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: MehdAiTheme.textSecondary, size: 20),
                      ),
                    ],
                  ),
                ),
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildEntry(
                          '🐯',
                          'THE DEN',
                          'The core AI engine. 11 specialized agents hold a secure boardroom meeting to analyze every trade. No single model decides alone — consensus is law.',
                          MehdAiTheme.gold,
                        ),
                        _buildEntry(
                          '🤖',
                          '11 AGENTS (3 LAYERS)',
                          '• The Underworld — Data layer (DON, PHANTOM, ORACLE)\n'
                          '• The Empire — Strategy layer (CAESAR, SAGE, GUARDIAN)\n'
                          '• Olympus — Math + Oversight (TITAN, ATLAS, FORGE, THE DON, SENTINEL)',
                          MehdAiTheme.blue,
                        ),
                        _buildEntry(
                          '🔒',
                          'SOVEREIGN LOCK',
                          'The trade button only unlocks when 7+ of 11 agents agree. If consensus is not reached, execution is physically blocked. No manual override exists.',
                          MehdAiTheme.purple,
                        ),
                        _buildEntry(
                          '⚙️',
                          'HARD RISK KERNEL',
                          'An unbreakable mathematical engine that restricts every trade to max 1% account risk. It calculates lot size, enforces stop-loss placement, and cannot be bypassed.',
                          MehdAiTheme.green,
                        ),
                        _buildEntry(
                          '🛡️',
                          'STOP GUARDIAN',
                          'If you hit 3 consecutive losses or exhibit emotional trading patterns, the Stop Guardian locks your account for 24 hours. This prevents revenge trading from destroying your capital.',
                          MehdAiTheme.red,
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Text(
                            'Capital is a seed, not a sacrifice.',
                            style: MehdAiTheme.terminalStyle.copyWith(
                              color: MehdAiTheme.gold,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEntry(String emoji, String title, String body, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                  style: MehdAiTheme.terminalStyle.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  )),
                const SizedBox(height: 4),
                Text(body,
                  style: MehdAiTheme.labelStyle.copyWith(
                    color: MehdAiTheme.textSecondary,
                    height: 1.5,
                    fontSize: 12,
                  )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
