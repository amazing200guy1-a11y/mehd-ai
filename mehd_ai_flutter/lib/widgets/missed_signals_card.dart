import 'package:flutter/material.dart';
import 'package:mehd_ai_flutter/core/theme.dart';

class MissedSignalsCard extends StatelessWidget {
  final int missedCount;
  final String exampleMissed;
  final VoidCallback onDismiss;
  /// The delay in seconds applied to free-tier signal feeds.
  /// RULE 9: Must reflect real backend config, not a hardcoded guess.
  final int delaySeconds;

  const MissedSignalsCard({
    super.key,
    required this.missedCount,
    required this.exampleMissed,
    required this.onDismiss,
    this.delaySeconds = 60,
  });

  @override
  Widget build(BuildContext context) {
    if (missedCount <= 0 && exampleMissed.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0D1117), // Deep terminal background
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: MehdAiTheme.blue.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: MehdAiTheme.blue.withOpacity(0.1),
              blurRadius: 15,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF0A1929),
                borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
                border: Border(bottom: BorderSide(color: Color(0xFF1A3A5C))),
              ),
              child: Row(
                children: [
                  const Text("🌅", style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(
                    'WHILE YOU WERE AWAY',
                    style: MehdAiTheme.terminalStyle.copyWith(
                      color: const Color(0xFFE5C07B), // Warm amber
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: MehdAiTheme.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      'FREE TIER · DELAYED ${delaySeconds}S',
                      style: MehdAiTheme.terminalStyle.copyWith(
                        color: MehdAiTheme.red,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: onDismiss,
                    child: const Icon(Icons.close, color: Color(0xFF666666), size: 16),
                  ),
                ],
              ),
            ),
            
            // Body
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (exampleMissed.isNotEmpty) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Missed: ", style: TextStyle(color: Color(0xFF888888), fontSize: 13, fontFamily: 'RobotoMono')),
                        Expanded(
                          child: Text(
                            exampleMissed,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'RobotoMono'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text("→ ", style: TextStyle(color: MehdAiTheme.green, fontSize: 13, fontFamily: 'RobotoMono')),
                        Text(
                          "Would have gained approx. +15-25 pips",
                          style: TextStyle(color: MehdAiTheme.green.withOpacity(0.9), fontSize: 13, fontStyle: FontStyle.italic, fontFamily: 'RobotoMono'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  if (missedCount > 1) ...[
                    Text(
                      "...and $missedCount other profitable setups.",
                      style: const TextStyle(color: Color(0xFF888888), fontSize: 12, fontFamily: 'RobotoMono'),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Operative Requirement Label (No clickable upgrade link)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF333333)),
                    ),
                    child: const Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lock, color: Color(0xFF888888), size: 16),
                            SizedBox(width: 8),
                            Text(
                              "REQUIRES INSTITUTIONAL TIER",
                              style: TextStyle(
                                color: Color(0xFF888888),
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
