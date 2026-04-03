import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mehd_ai_flutter/core/theme.dart';

class HeatmapScreen extends StatelessWidget {
  const HeatmapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MehdAiTheme.bgPrimary,
      appBar: AppBar(
        title: Text('Global Consensus Heatmap', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: MehdAiTheme.bgSecondary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'LIVE MARKET VIEWS',
              style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.blue, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'A bird\'s-eye view of every major currency pair as seen by the 11-agent Den. Squares turn green for unanimous BUY, red for SELL, grey for HOLD or disagreement.',
              style: MehdAiTheme.labelStyle.copyWith(fontSize: 14),
            ),
            const SizedBox(height: 32),
            _buildHeatmapGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeatmapGrid() {
    final pairs = [
      {'symbol': 'EUR/USD', 'state': 'BUY', 'conf': 88.5},
      {'symbol': 'GBP/USD', 'state': 'BUY', 'conf': 76.2},
      {'symbol': 'USD/JPY', 'state': 'HOLD', 'conf': 45.0},
      {'symbol': 'AUD/USD', 'state': 'HOLD', 'conf': 52.1},
      {'symbol': 'USD/CAD', 'state': 'SELL', 'conf': 81.0},
      {'symbol': 'NZD/USD', 'state': 'BUY', 'conf': 72.9},
      {'symbol': 'EUR/GBP', 'state': 'SELL', 'conf': 91.2},
      {'symbol': 'EUR/JPY', 'state': 'HOLD', 'conf': 33.3},
      {'symbol': 'GBP/JPY', 'state': 'SELL', 'conf': 85.0},
    ];

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 150,
        childAspectRatio: 1.0,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: pairs.length,
      itemBuilder: (context, index) {
        final pair = pairs[index];
        final state = pair['state'] as String;
        final conf = pair['conf'] as double;
        final symbol = pair['symbol'] as String;

        Color bgColor;
        if (state == 'BUY') {
          bgColor = MehdAiTheme.green.withOpacity(0.2);
        } else if (state == 'SELL') {
          bgColor = MehdAiTheme.red.withOpacity(0.2);
        } else {
          bgColor = Colors.grey.withOpacity(0.1);
        }

        Color textColor;
        if (state == 'BUY') {
          textColor = MehdAiTheme.green;
        } else if (state == 'SELL') {
          textColor = MehdAiTheme.red;
        } else {
          textColor = Colors.grey;
        }

        return Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: textColor.withOpacity(0.5)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                symbol,
                style: GoogleFonts.jetBrainsMono(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                state,
                style: MehdAiTheme.terminalStyle.copyWith(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              if (state != 'HOLD') ...[
                const SizedBox(height: 4),
                Text(
                  '$conf%',
                  style: MehdAiTheme.terminalStyle.copyWith(color: textColor.withOpacity(0.8), fontSize: 12),
                ),
              ]
            ],
          ),
        );
      },
    );
  }
}
