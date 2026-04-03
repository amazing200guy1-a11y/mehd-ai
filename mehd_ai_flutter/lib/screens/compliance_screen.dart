import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mehd_ai_flutter/core/theme.dart';

class ComplianceScreen extends StatelessWidget {
  const ComplianceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MehdAiTheme.bgPrimary,
      appBar: AppBar(
        title: Text('Compliance & Audit', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: MehdAiTheme.bgSecondary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCertificate(),
            const SizedBox(height: 32),
            _buildAuditLogs(),
          ],
        ),
      ),
    );
  }

  Widget _buildCertificate() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: MehdAiTheme.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MehdAiTheme.gold),
        boxShadow: [
          BoxShadow(
            color: MehdAiTheme.gold.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 5,
          )
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.verified, color: MehdAiTheme.gold, size: 48),
          const SizedBox(height: 16),
          Text(
            'CERTIFICATE OF INTELLIGENCE',
            style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.gold, fontSize: 24, letterSpacing: 2),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'This institution is operating under Mehd AI Consensus-Verified™ execution standards.\nAll algorithmic risk limits are strictly enforced by the HardRiskKernel.',
            style: MehdAiTheme.labelStyle.copyWith(fontSize: 14, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAuditLogs() {
    final List<Map<String, String>> logs = [
      {'time': '2024-03-18 14:32:07 UTC', 'event': 'Consensus 8/11 Reached (EUR/USD)'},
      {'time': '2024-03-18 14:32:08 UTC', 'event': 'HardRiskKernel Approved (Lot: 1.2)'},
      {'time': '2024-03-18 14:32:09 UTC', 'event': 'Execution Confirmed (Latency: 14ms)'},
      {'time': '2024-03-18 10:15:22 UTC', 'event': 'SENTINEL FREEZE — Paradox Detected (JPY)'},
      {'time': '2024-03-18 08:44:11 UTC', 'event': 'Post-Mortem: Constitution Amended (Rule 042)'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('IMMUTABLE AUDIT TRAIL', style: MehdAiTheme.labelStyle),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1117),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF30363D)),
          ),
          child: Column(
            children: logs.map((log) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                children: [
                  Text('[${log['time']}]', style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.textSecondary, fontSize: 13)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(log['event']!, style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.green, fontSize: 13)),
                  ),
                ],
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }
}
