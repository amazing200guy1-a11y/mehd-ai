import 'package:flutter/material.dart';
import 'package:mehd_ai_flutter/core/theme.dart';

class HistoryTab extends StatelessWidget {
  const HistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    // Awaiting real history feed
    final List<Map<String, dynamic>> history = [];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: MehdAiTheme.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: MehdAiTheme.purple.withOpacity(0.2)),
              ),
              child: const Icon(Icons.history_rounded, color: MehdAiTheme.purple, size: 22),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("CLOSED TRADES", style: MehdAiTheme.headingStyle.copyWith(fontSize: 16)),
                const SizedBox(height: 4),
                Text("Verified execution record", style: MehdAiTheme.labelStyle.copyWith(fontSize: 12)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (history.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
            decoration: BoxDecoration(
              color: MehdAiTheme.surface(context),
              borderRadius: BorderRadius.circular(MehdAiTheme.borderRadius),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: MehdAiTheme.purple.withOpacity(0.07),
                    border: Border.all(color: MehdAiTheme.purple.withOpacity(0.2)),
                  ),
                  child: const Icon(Icons.receipt_long_rounded, color: MehdAiTheme.purple, size: 36),
                ),
                const SizedBox(height: 20),
                const Text(
                  'NO TRADE HISTORY YET',
                  style: TextStyle(color: Colors.white60, fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 1),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Every trade executed by the Sniper will\nappear here with a full audit trail.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white38, fontSize: 13, height: 1.6),
                ),
              ],
            ),
          )
        else
          ...history.map((h) => _buildHistoryTile(context, h)),
      ],
    );
  }

  Widget _buildHistoryTile(BuildContext context, Map<String, dynamic> trade) {
    final pnl = trade['pnl'] as double;
    final pnlColor = pnl >= 0 ? MehdAiTheme.green : MehdAiTheme.red;
    final sign = pnl >= 0 ? "+" : "";

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: MehdAiTheme.surface(context),
        borderRadius: BorderRadius.circular(MehdAiTheme.borderRadius),
        border: Border.all(color: pnlColor.withOpacity(0.18)),
      ),
      child: ExpansionTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("${trade['symbol']} ${trade['direction']}",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            Text("$sign\$${pnl.toStringAsFixed(2)}",
              style: TextStyle(color: pnlColor, fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'monospace')),
          ],
        ),
        iconColor: Colors.white54,
        collapsedIconColor: Colors.white54,
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          const Divider(color: Colors.white10, height: 24),
          _buildDetailRow("Entry Logic", trade['entry_logic']),
          _buildDetailRow("Sniper State", trade['sniper_state']),
          _buildDetailRow("Exit Reason", trade['exit_reason']),
          _buildDetailRow("Risk Engine", trade['risk_decision']),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4)),
          ),
        ],
      ),
    );
  }
}
