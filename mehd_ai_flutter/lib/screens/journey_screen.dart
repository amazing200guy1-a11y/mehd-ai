import 'package:flutter/material.dart';
import 'package:mehd_ai_flutter/core/theme.dart';
import 'package:mehd_ai_flutter/widgets/protection_score.dart';

/// FILE — journey_screen.dart
///
/// Build Debrief:
/// Mehd AI guarantees to compress 8 years of forex learning into 6 months.
/// The Journey Screen is where we prove it visually.
/// 
/// Key Features Built:
/// 1. Timeline Visualization: Shows Week 1 through Week 24 (6 months) showing 
///    the exact phase they are in (e.g., Phase 1: Capital Preservation).
/// 2. Protection Score: The HardRiskKernel's rating on how disciplined the trader was.
/// 3. Mistake DNA: A brutal, honest breakdown of their flaws. e.g. "You revenge 
///    trade on Fridays" or "You ignore the Math Room on XAU/USD". This builds 
///    massive accountability.

class JourneyScreen extends StatelessWidget {
  const JourneyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MehdAiTheme.bgPrimary,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.rocket_launch, color: MehdAiTheme.purple),
            const SizedBox(width: 8),
            Text('YOUR JOURNEY', style: MehdAiTheme.headingStyle.copyWith(letterSpacing: 2)),
          ],
        ),
        backgroundColor: MehdAiTheme.bgSecondary,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: MehdAiTheme.borderColor, height: 1),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        children: [
          _buildHeader(),
          const SizedBox(height: 32),
          
          // Row configuration
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Timeline List
              Expanded(
                flex: 3,
                child: _buildTimeline(),
              ),
              const SizedBox(width: 24),
              // Right: Stats & DNA
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    const ProtectionScore(score: 92),
                    const SizedBox(height: 24),
                    _buildMistakeDNA(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '6-MONTH TRANSFORMATION',
              style: MehdAiTheme.headingStyle.copyWith(color: MehdAiTheme.textSecondary, letterSpacing: 1),
            ),
            Builder(
              builder: (ctx) => InkWell(
                onTap: () {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      backgroundColor: MehdAiTheme.blue,
                      content: Text("Share Card: My Den configuration achieved Certified Alpha +14.2% vs market average | Mehd AI", style: MehdAiTheme.terminalStyle.copyWith(color: Colors.white)),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: MehdAiTheme.yellow.withOpacity(0.1),
                    border: Border.all(color: MehdAiTheme.yellow),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.workspace_premium, color: MehdAiTheme.yellow, size: 16),
                      const SizedBox(width: 6),
                      Text('CERTIFIED ALPHA', style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.yellow, fontWeight: FontWeight.bold, fontSize: 10)),
                    ]
                  )
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Compressing 8 years of failure into 24 weeks of discipline.',
          style: MehdAiTheme.labelStyle.copyWith(fontSize: 14, color: MehdAiTheme.textPrimary),
        ),
        const SizedBox(height: 16),
        LinearProgressIndicator(
          value: 3 / 24, // Week 3
          backgroundColor: MehdAiTheme.bgTertiary,
          valueColor: const AlwaysStoppedAnimation<Color>(MehdAiTheme.blue),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Week 3', style: MehdAiTheme.labelStyle.copyWith(color: MehdAiTheme.blue, fontWeight: FontWeight.bold)),
            Text('Week 24', style: MehdAiTheme.labelStyle),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeline() {
    return Container(
      decoration: BoxDecoration(
        color: MehdAiTheme.bgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MehdAiTheme.borderColor),
      ),
      child: Column(
        children: [
          _buildPhase(1, 'Survival & Preservation', 'Weeks 1-4', true, true),
          const Divider(color: MehdAiTheme.borderColor, height: 1),
          _buildPhase(2, 'Pattern Recognition', 'Weeks 5-8', false, false),
          const Divider(color: MehdAiTheme.borderColor, height: 1),
          _buildPhase(3, 'Execution Edge', 'Weeks 9-16', false, false),
          const Divider(color: MehdAiTheme.borderColor, height: 1),
          _buildPhase(4, 'Unconscious Competence', 'Weeks 17-24', false, false),
        ],
      ),
    );
  }

  Widget _buildPhase(int num, String title, String weeks, bool active, bool completed) {
    Color iconColor = MehdAiTheme.textSecondary;
    if (active) iconColor = MehdAiTheme.blue;
    if (completed && !active) iconColor = MehdAiTheme.green;

    return Container(
      padding: const EdgeInsets.all(16),
      color: active ? MehdAiTheme.blue.withOpacity(0.05) : Colors.transparent,
      child: Row(
        children: [
          Icon(
            completed ? Icons.check_circle : (active ? Icons.play_circle_fill : Icons.lock_outline),
            color: iconColor,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PHASE $num • $weeks', style: MehdAiTheme.labelStyle.copyWith(fontSize: 10, color: active ? MehdAiTheme.blue : MehdAiTheme.textSecondary)),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: MehdAiTheme.terminalStyle.copyWith(
                    fontWeight: active ? FontWeight.bold : FontWeight.normal,
                    color: active ? MehdAiTheme.textPrimary : MehdAiTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMistakeDNA() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MehdAiTheme.bgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MehdAiTheme.red.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: MehdAiTheme.red.withOpacity(0.05),
            blurRadius: 20,
            spreadRadius: 2,
          )
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.fingerprint, color: MehdAiTheme.red, size: 20),
              const SizedBox(width: 8),
              Text('YOUR MISTAKE DNA', style: MehdAiTheme.headingStyle.copyWith(color: MehdAiTheme.red)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'The Don tracks every action to find your distinct failure patterns.',
            style: MehdAiTheme.labelStyle,
          ),
          const SizedBox(height: 20),
          _buildDNATrait('REVENGE TRADING', '42% of losses occur within 1 hour of a previous loss. Sage flagged emotional tilt.', 0.8),
          const SizedBox(height: 16),
          _buildDNATrait('SESSION IGNORANCE', 'You ignore The Underworld during high-impact news on USD pairs. Sentinel recorded this.', 0.6),
          const SizedBox(height: 16),
          _buildDNATrait('OVER-LEVERAGING', 'You risk 3% instead of 1% when winning. Atlas calculated ruin probability at 14%.', 0.9),
        ],
      ),
    );
  }

  Widget _buildDNATrait(String title, String desc, double severity) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: MehdAiTheme.terminalStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 12)),
            Text('${(severity * 100).toInt()}% Severity', style: MehdAiTheme.labelStyle.copyWith(color: MehdAiTheme.red)),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: severity,
          backgroundColor: MehdAiTheme.bgTertiary,
          valueColor: const AlwaysStoppedAnimation<Color>(MehdAiTheme.red),
          minHeight: 4,
        ),
        const SizedBox(height: 8),
        Text(desc, style: MehdAiTheme.labelStyle.copyWith(color: MehdAiTheme.textSecondary, height: 1.4)),
      ],
    );
  }
}
