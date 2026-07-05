import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:mehd_ai_flutter/models/executive_brief.dart';
import 'package:mehd_ai_flutter/core/theme.dart';
import 'package:mehd_ai_flutter/core/den_identity.dart';

class ExecutiveBriefDialog extends StatelessWidget {
  final ExecutiveBrief brief;

  const ExecutiveBriefDialog({super.key, required this.brief});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            width: 600,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF58A6FF).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF58A6FF).withOpacity(0.12),
                width: 0.5,
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(child: Text('DEN EXECUTIVE BRIEF', style: MehdAiTheme.terminalStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis)),
                        IconButton(
                          icon: const Icon(Icons.share, color: MehdAiTheme.textSecondary, size: 20),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: MehdAiTheme.blue,
                                content: Text('Brief shared to encrypted vault.', style: MehdAiTheme.terminalStyle.copyWith(color: Colors.white)),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    Text('Den Analysis™ by Mehd AI', style: MehdAiTheme.labelStyle, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 12),
                    const Divider(color: MehdAiTheme.borderColor),
                    
                    _buildSectionHeader('THE RESEARCH'),
                    ...brief.sentimentLayer.entries.map((e) => _buildVoteRow(e.key, e.value)),
                    const SizedBox(height: 12),
                    
                    _buildSectionHeader('THE STRATEGY'),
                    ...brief.strategyLayer.entries.map((e) => _buildVoteRow(e.key, e.value)),
                    const SizedBox(height: 12),
                    
                    _buildSectionHeader('OLYMPUS'),
                    ...brief.mathLayer.entries.map((e) => _buildVoteRow(e.key, e.value)),
                    const SizedBox(height: 12),
                    
                    _buildSectionHeader('THE DON SYNTHESIS'),
                    Text('Confidence: ${brief.consensusScore}', style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.textPrimary, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text('"${brief.decisionBasis}"', style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.gold, height: 1.5), overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 16),
                    
                    _buildRow('SENTINEL:', 'All clear ✓'),
                    _buildRow('KERNEL:', 'Risk approved ✓'),
                    const SizedBox(height: 8),
                    Text('Den Analysis™ Certificate', style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.textSecondary, fontStyle: FontStyle.italic), overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 24),
                    
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MehdAiTheme.green.withOpacity(0.1),
                        side: const BorderSide(color: MehdAiTheme.green),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('ACKNOWLEDGE & CLOSE', style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.green), overflow: TextOverflow.ellipsis),
                    )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
      child: Text(title, style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.blue, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text(label, style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.textSecondary), overflow: TextOverflow.ellipsis)),
          Expanded(child: Text(value, style: MehdAiTheme.terminalStyle, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _buildVoteRow(String model, String voteStr) {
    final identity = DenIdentity.getIdentity(model);
    final displayName = identity.displayName != 'UNKNOWN' ? identity.displayName : model;
    
    final isHold = voteStr.contains('HOLD');
    final isSell = voteStr.contains('SELL');
    final Color voteColor = isHold ? MehdAiTheme.textSecondary : (isSell ? MehdAiTheme.red : MehdAiTheme.green);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: RichText(
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          style: MehdAiTheme.terminalStyle,
          children: [
            TextSpan(text: '${displayName.padRight(8)}: ', style: const TextStyle(fontWeight: FontWeight.bold, color: MehdAiTheme.textPrimary)),
            TextSpan(text: voteStr, style: TextStyle(color: voteColor)),
          ],
        ),
      ),
    );
  }
}
