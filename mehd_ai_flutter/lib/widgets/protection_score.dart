import 'package:flutter/material.dart';
import 'package:mehd_ai_flutter/core/theme.dart';

/// FILE — protection_score.dart
///
/// Build Debrief:
/// The Protection Score is the cornerstone of the trader's journey.
/// It gamifies risk management. It drops when they over-leverage or tilt,
/// and it rises when they respect the AI's verdicts.

class ProtectionScore extends StatelessWidget {
  final int score;

  const ProtectionScore({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    Color scoreColor = MehdAiTheme.bgTertiary;
    if (score >= 90) {
      scoreColor = MehdAiTheme.blue;
    } else if (score >= 70) {
      scoreColor = MehdAiTheme.green;
    } else if (score >= 40) {
      scoreColor = MehdAiTheme.yellow;
    } else {
      scoreColor = MehdAiTheme.red;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scoreColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scoreColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'PROTECTION SCORE',
            style: MehdAiTheme.labelStyle.copyWith(letterSpacing: 2, fontSize: 11),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 8,
                  backgroundColor: MehdAiTheme.bgSecondary,
                  valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                ),
              ),
              Column(
                children: [
                  Text(
                    '$score',
                    style: MehdAiTheme.headingStyle.copyWith(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: scoreColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '/ 100',
                    style: MehdAiTheme.labelStyle.copyWith(fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _getScoreMessage(),
            textAlign: TextAlign.center,
            style: MehdAiTheme.terminalStyle.copyWith(fontSize: 12, color: MehdAiTheme.textSecondary),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _getScoreMessage() {
    if (score >= 90) return 'The Don protects you completely.';
    if (score >= 70) return 'Solid execution. The Empire acknowledges.';
    if (score >= 40) return 'Warning: Emotional trading. Sentinel watching.';
    return 'CRITICAL: The Den has locked your capital.';
  }
}
