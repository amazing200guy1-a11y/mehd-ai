import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mehd_ai_flutter/core/theme.dart';

/// FIX 3: Reusable legal disclaimer widget.
/// Shows at the bottom of every screen. Tap to expand full terms.

class LegalDisclaimer extends StatelessWidget {
  final bool expanded;
  const LegalDisclaimer({super.key, this.expanded = false});

  static const String shortText =
      'Mehd AI is for educational purposes only. Not financial advice. '
      'Trade at your own risk. Past performance does not guarantee future results.';

  static const String fullText =
      'DISCLAIMER: Mehd AI is an educational tool that uses artificial intelligence '
      'to analyze market data. It does not constitute financial advice, investment '
      'recommendations, or a solicitation to trade. All trading involves risk, and '
      'you should never trade with money you cannot afford to lose. Mehd AI accepts '
      'no liability for trading decisions made based on this analysis. By using this '
      'app, you agree to our Terms of Service and Privacy Policy.';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: MehdAiTheme.borderColor.withOpacity(0.3))),
      ),
      child: GestureDetector(
        onTap: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            builder: (ctx) => BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xDD000000), // Glass deep black
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.5),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40, height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Flexible(child: Text('Legal Notice', style: MehdAiTheme.headingStyle, overflow: TextOverflow.ellipsis)),
                    const SizedBox(height: 16),
                    Flexible(child: Text(fullText, style: MehdAiTheme.labelStyle.copyWith(fontSize: 12, height: 1.6), overflow: TextOverflow.ellipsis)),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text('Close Acknowledgement', style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.blue, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        child: Text(
          shortText,
          style: MehdAiTheme.labelStyle.copyWith(
            fontSize: 11,
            color: MehdAiTheme.textSecondary.withOpacity(0.6),
            height: 1.4,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
