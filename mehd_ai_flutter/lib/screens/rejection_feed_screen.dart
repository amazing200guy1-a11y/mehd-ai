import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mehd_ai_flutter/core/theme.dart';
import 'package:intl/intl.dart';

/// FILE — rejection_feed_screen.dart
/// UPGRADE 4: Live Rejection Feed
/// A high-impact screen showing exactly what The Den protected the user from.

class RejectionFeedScreen extends StatefulWidget {
  const RejectionFeedScreen({super.key});

  @override
  State<RejectionFeedScreen> createState() => _RejectionFeedScreenState();
}

class _RejectionFeedScreenState extends State<RejectionFeedScreen> {
  // Mock data for rejected trades (in production, this would stream from Firestore)
  final List<Map<String, dynamic>> _rejections = [
    {
      'symbol': 'EUR/USD',
      'direction': 'BUY',
      'reason': 'Math Layer Veto',
      'details': 'Sovereign Lock failed. Consensus at 8/11. TITAN detected anomalous spread structure.',
      'time': DateTime.now().subtract(const Duration(minutes: 12)),
      'agents_vetoed': ['TITAN', 'SAGE', 'ORACLE'],
      'saved_amount': 250.00,
    },
    {
      'symbol': 'GBP/JPY',
      'direction': 'SELL',
      'reason': 'HardRisk Kernel Lock',
      'details': 'Trade rejected. 1.0% risk rule exceeded based on current account drawdown constraints.',
      'time': DateTime.now().subtract(const Duration(hours: 2)),
      'agents_vetoed': ['SENTINEL'],
      'saved_amount': 185.50,
    },
    {
      'symbol': 'XAU/USD',
      'direction': 'BUY',
      'reason': 'Black Swan Threat (L2)',
      'details': 'High impact FOMC data release imminent. All new executions locked until volatility normalizes.',
      'time': DateTime.now().subtract(const Duration(hours: 8)),
      'agents_vetoed': ['GROK', 'PERPLEXITY', 'GEMINI'],
      'saved_amount': null, // Unquantifiable preservation
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Calculate total explicitly saved money
    final totalSaved = _rejections
        .where((r) => r['saved_amount'] != null)
        .fold<double>(0.0, (sum, item) => sum + (item['saved_amount'] as double));

    return Scaffold(
      backgroundColor: MehdAiTheme.bgPrimary,
      appBar: AppBar(
        title: Text('Rejection Feed', style: MehdAiTheme.headingStyle),
        backgroundColor: MehdAiTheme.bgSecondary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: MehdAiTheme.blue),
            tooltip: 'Share Protection Stats',
            onPressed: () => _shareStats(totalSaved),
          )
        ],
      ),
      body: Column(
        children: [
          _buildStatsHeader(totalSaved),
          const Divider(height: 1, color: MehdAiTheme.borderColor),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _rejections.length,
              itemBuilder: (context, index) {
                return _buildRejectionCard(_rejections[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader(double totalSaved) {
    // Live counters (in production, these stream from Firestore)
    final int totalAnalyses = 847;
    final int approved = 23;
    final int rejected = _rejections.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      color: MehdAiTheme.bgSecondary,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: MehdAiTheme.shieldColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield, size: 48, color: MehdAiTheme.shieldColor),
          ),
          const SizedBox(height: 16),
          Text(
            'CAPITAL PRESERVED',
            style: GoogleFonts.jetBrainsMono(
              color: MehdAiTheme.shieldColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${totalSaved.toStringAsFixed(2)}+',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          // Live Counters Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildCounter('Analyses', totalAnalyses, MehdAiTheme.blue),
              _buildCounter('Approved', approved, MehdAiTheme.green),
              _buildCounter('Rejected', rejected, MehdAiTheme.red),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'The Den actively prevented ruin across $rejected trades.',
            textAlign: TextAlign.center,
            style: MehdAiTheme.labelStyle.copyWith(color: MehdAiTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildCounter(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: GoogleFonts.inter(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: MehdAiTheme.labelStyle.copyWith(
            fontSize: 10,
            color: MehdAiTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildRejectionCard(Map<String, dynamic> rejection) {
    final symbol = rejection['symbol'] as String;
    final reason = rejection['reason'] as String;
    final details = rejection['details'] as String;
    final direction = rejection['direction'] as String;
    final time = rejection['time'] as DateTime;
    final agents = List<String>.from(rejection['agents_vetoed'] as List);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: MehdAiTheme.bgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MehdAiTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: MehdAiTheme.borderColor)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.block, color: MehdAiTheme.red, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '$direction $symbol BLOCKED',
                      style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.red, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Text(
                  DateFormat('MMM d, HH:mm').format(time),
                  style: MehdAiTheme.labelStyle.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reason, style: MehdAiTheme.headingStyle.copyWith(fontSize: 16)),
                const SizedBox(height: 6),
                Text(details, style: MehdAiTheme.labelStyle.copyWith(height: 1.5)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: agents.map((agent) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: MehdAiTheme.bgTertiary,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: MehdAiTheme.borderColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.close, size: 12, color: MehdAiTheme.red),
                        const SizedBox(width: 4),
                        Text(agent, style: MehdAiTheme.terminalStyle.copyWith(fontSize: 10, color: MehdAiTheme.red)),
                      ],
                    ),
                  )).toList(),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _shareStats(double totalSaved) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: MehdAiTheme.blue,
        content: Text(
          "Link copied! The Den has saved you \$${totalSaved.toStringAsFixed(2)} so far.",
          style: MehdAiTheme.terminalStyle.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}
