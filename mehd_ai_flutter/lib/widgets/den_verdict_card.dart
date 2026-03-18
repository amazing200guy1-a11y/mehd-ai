import 'package:flutter/material.dart';
import 'package:mehd_ai_flutter/core/theme.dart';
import 'package:mehd_ai_flutter/models/consensus_result.dart';

/// FILE — den_verdict_card.dart
///
/// Build Debrief:
/// The DenVerdictCard is the ultimate output of the 9-model consensus.
/// It sits at the top of the Strategy Room. It instantly tells the user
/// the final trading direction, the consensus percentage, and whether
/// the trade is approved to proceed according to Hard Risk rules.

class DenVerdictCard extends StatelessWidget {
  final ConsensusResult consensus;

  const DenVerdictCard({super.key, required this.consensus});

  @override
  Widget build(BuildContext context) {
    final isBuy = consensus.finalDirection == 'BUY';
    final isSell = consensus.finalDirection == 'SELL';
    
    Color verdictColor = MehdAiTheme.textSecondary;
    if (isBuy) verdictColor = MehdAiTheme.green;
    if (isSell) verdictColor = MehdAiTheme.red;

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: MehdAiTheme.bgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: consensus.proceed ? verdictColor.withOpacity(0.5) : MehdAiTheme.borderColor,
          width: consensus.proceed ? 2 : 1,
        ),
        boxShadow: consensus.proceed ? [
          BoxShadow(
            color: verdictColor.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 2,
          )
        ] : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'THE DEN VERDICT',
                style: MehdAiTheme.headingStyle.copyWith(
                  letterSpacing: 2,
                  color: MehdAiTheme.textSecondary,
                ),
              ),
              _buildConsensusBadge(),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                consensus.finalDirection,
                style: MehdAiTheme.headingStyle.copyWith(
                  fontSize: 32,
                  color: consensus.proceed ? verdictColor : MehdAiTheme.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  consensus.proceed ? 'CLEARED FOR EXECUTION' : 'EXECUTION LOCKED',
                  style: MehdAiTheme.terminalStyle.copyWith(
                    fontSize: 12,
                    color: consensus.proceed ? MehdAiTheme.textPrimary : MehdAiTheme.red,
                  ),
                ),
              ),
            ],
          ),
          if (!consensus.proceed && consensus.rejectionReason != null && consensus.rejectionReason!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: MehdAiTheme.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: MehdAiTheme.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: MehdAiTheme.red, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      consensus.rejectionReason!,
                      style: MehdAiTheme.labelStyle.copyWith(color: MehdAiTheme.red),
                    ),
                  ),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildConsensusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: MehdAiTheme.blue.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: MehdAiTheme.blue.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline, color: MehdAiTheme.blue, size: 14),
          const SizedBox(width: 6),
          Text(
            '${consensus.consensusPercentage.toInt()}% AGREEMENT',
            style: MehdAiTheme.labelStyle.copyWith(color: MehdAiTheme.blue, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
