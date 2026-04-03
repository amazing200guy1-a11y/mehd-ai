import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mehd_ai_flutter/core/theme.dart';

class ApiDocsScreen extends StatelessWidget {
  const ApiDocsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MehdAiTheme.bgPrimary,
      appBar: AppBar(
        title: Text('Consensus API', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: MehdAiTheme.bgSecondary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CONSENSUS AS A SERVICE',
              style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.purple, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Plug Mehd AI directly into your fund\'s execution algorithms to prevent catastrophic drawdowns. '
              'The Den will veto trades that violate our consensus parameters.',
              style: MehdAiTheme.labelStyle.copyWith(fontSize: 14),
            ),
            const SizedBox(height: 32),
            _buildKeyCard(context),
            const SizedBox(height: 32),
            _buildEndpointDemo(),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyCard(BuildContext context) {
    const apiKey = 'mehd_sk_live_institutional';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MehdAiTheme.bgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MehdAiTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.key, color: MehdAiTheme.gold, size: 20),
              const SizedBox(width: 8),
              Text('API KEY - INSTITUTIONAL TIER', style: MehdAiTheme.labelStyle),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    apiKey,
                    style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.green),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.copy, color: MehdAiTheme.textSecondary),
                onPressed: () {
                  Clipboard.setData(const ClipboardData(text: apiKey));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(backgroundColor: MehdAiTheme.green, content: Text('API Key copied to clipboard', style: MehdAiTheme.terminalStyle)),
                  );
                },
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEndpointDemo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ENDPOINT: /api/consensus-validate',
          style: MehdAiTheme.terminalStyle.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1117),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF30363D)),
          ),
          child: SelectableText(
            '''curl -X POST "https://api.mehd.ai/v1/consensus-validate" \\
  -H "Authorization: Bearer mehd_sk_live_institutional" \\
  -H "Content-Type: application/json" \\
  -d '{
    "symbol": "EUR/USD",
    "proposed_direction": "BUY"
  }'

===================================
RESPONSE
===================================
{
  "is_approved": false,
  "confidence": 42.1,
  "message": "Den vetoes this trade due to divergent quant models."
}''',
            style: MehdAiTheme.terminalStyle.copyWith(color: const Color(0xFF8B949E), height: 1.5),
          ),
        ),
      ],
    );
  }
}
