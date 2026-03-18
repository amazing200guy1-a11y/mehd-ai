import 'package:flutter/material.dart';
import 'package:mehd_ai_flutter/models/executive_brief.dart';
import 'package:mehd_ai_flutter/core/theme.dart';
import 'package:intl/intl.dart';

class ExecutiveBriefDialog extends StatelessWidget {
  final ExecutiveBrief brief;

  const ExecutiveBriefDialog({super.key, required this.brief});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: MehdAiTheme.bgSecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: MehdAiTheme.borderColor),
      ),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('DEN EXECUTIVE BRIEF', style: MehdAiTheme.terminalStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 16)),
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
              const Divider(color: MehdAiTheme.borderColor),
              _buildRow('Symbol:', brief.symbol),
              _buildRow('Timestamp:', '${DateFormat('yyyy-MM-dd HH:mm:ss').format(brief.timestamp.toLocal())} Local'),
              _buildRow('Final Verdict:', brief.finalVerdict),
              _buildRow('Consensus:', brief.consensusScore),
              const SizedBox(height: 16),
              
              _buildSectionHeader('SENTIMENT LAYER'),
              ...brief.sentimentLayer.entries.map((e) => _buildVoteRow(e.key, e.value)),
              const SizedBox(height: 12),
              
              _buildSectionHeader('STRATEGY LAYER'),
              ...brief.strategyLayer.entries.map((e) => _buildVoteRow(e.key, e.value)),
              const SizedBox(height: 12),
              
              _buildSectionHeader('MATH LAYER'),
              ...brief.mathLayer.entries.map((e) => _buildVoteRow(e.key, e.value)),
              const SizedBox(height: 12),
              
              _buildSectionHeader('RISK KERNEL VERIFICATION'),
              ...brief.riskVerification.entries.map((e) => _buildRow('${e.key}:', e.value)),
              const SizedBox(height: 12),

              _buildSectionHeader('DECISION BASIS'),
              Text(brief.decisionBasis, style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.textSecondary, height: 1.5)),
              const SizedBox(height: 24),
              
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: MehdAiTheme.green.withOpacity(0.1),
                  side: const BorderSide(color: MehdAiTheme.green),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: Text('ACKNOWLEDGE & CLOSE', style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.green)),
              )
            ],
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
          SizedBox(width: 140, child: Text(label, style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.textSecondary))),
          Expanded(child: Text(value, style: MehdAiTheme.terminalStyle)),
        ],
      ),
    );
  }

  Widget _buildVoteRow(String model, String voteStr) {
    final isHold = voteStr.startsWith('HOLD');
    final isSell = voteStr.startsWith('SELL');
    final Color voteColor = isHold ? MehdAiTheme.textSecondary : (isSell ? MehdAiTheme.red : MehdAiTheme.green);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: RichText(
        text: TextSpan(
          style: MehdAiTheme.terminalStyle,
          children: [
            TextSpan(text: '$model: ', style: const TextStyle(fontWeight: FontWeight.bold, color: MehdAiTheme.textPrimary)),
            TextSpan(text: voteStr, style: TextStyle(color: voteColor)),
          ],
        ),
      ),
    );
  }
}
