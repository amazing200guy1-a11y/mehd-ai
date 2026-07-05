import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mehd_ai_flutter/core/theme.dart';
import 'package:mehd_ai_flutter/screens/terms_screen.dart';
import 'package:mehd_ai_flutter/screens/privacy_screen.dart';


class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MehdAiTheme.bgPrimary,
      appBar: AppBar(
        title: Text('About Mehd AI', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: MehdAiTheme.bgSecondary,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: MehdAiTheme.borderColor, height: 1),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/mehd_logo.png', width: 100, height: 100),
              const SizedBox(height: 24),
              Text('MEHD AI', style: MehdAiTheme.headingStyle.copyWith(fontSize: 32, letterSpacing: 4)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: MehdAiTheme.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: MehdAiTheme.blue.withOpacity(0.5)),
                ),
                child: Text('Version 1.0.0', style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.blue, fontSize: 12)),
              ),
              const SizedBox(height: 48),
              Text(
                '"Capital is a seed, not a sacrifice."',
                style: GoogleFonts.inter(
                  color: MehdAiTheme.gold,
                  fontSize: 18,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: 500,
                child: Text(
                  'Mehd AI is a Den Analysis trading assistant powered by The Den — an 11-agent Synthetic Institutional Intelligence system.\n\nBuilt to protect traders globally from losing money through unbreakable risk rules and multi-model AI consensus.',
                  style: MehdAiTheme.labelStyle.copyWith(fontSize: 16, height: 1.6, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 64),
              // Architecture Tree Text
              Column(
                children: [
                  Text('THE RESEARCH', style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.textSecondary, letterSpacing: 2)),
                  Container(width: 2, height: 16, color: MehdAiTheme.borderColor, margin: const EdgeInsets.symmetric(vertical: 8)),
                  Text('THE STRATEGY', style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.blue, letterSpacing: 2)),
                  Container(width: 2, height: 16, color: MehdAiTheme.borderColor, margin: const EdgeInsets.symmetric(vertical: 8)),
                  Text('OLYMPUS', style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.gold, letterSpacing: 2)),
                  Container(width: 2, height: 16, color: MehdAiTheme.borderColor, margin: const EdgeInsets.symmetric(vertical: 8)),
                  Text('THE DON · SENTINEL', style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.red, fontWeight: FontWeight.bold, letterSpacing: 2)),
                ],
              ),
              const SizedBox(height: 48),
              Text('Consensus-Verified Trading™', style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.textSecondary)),
              const SizedBox(height: 64),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildFooterLink('Terms of Service', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsScreen()))),
                  const SizedBox(width: 24),
                  _buildFooterLink('Privacy Policy', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyScreen()))),
                  const SizedBox(width: 24),
                  _buildFooterLink('Rate Mehd AI', color: MehdAiTheme.blue, onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: MehdAiTheme.blue,
                        content: Text('Thank you! Redirecting to App Store / Play Store...'),
                      ),
                    );
                  }),
                ],

              ),
              const SizedBox(height: 32),
              Text('© 2026 Mehd AI. All rights reserved.', style: MehdAiTheme.labelStyle.copyWith(color: MehdAiTheme.textSecondary.withOpacity(0.5))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooterLink(String label, {required VoidCallback onTap, Color color = MehdAiTheme.textSecondary}) {
    return InkWell(
      onTap: onTap,
      child: Text(
        '[$label]',
        style: MehdAiTheme.terminalStyle.copyWith(color: color, fontSize: 13),
      ),
    );
  }

}
