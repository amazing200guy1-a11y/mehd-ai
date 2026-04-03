import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mehd_ai_flutter/core/theme.dart';

/// FIX 3: Privacy Policy screen — accessible from settings without login.

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MehdAiTheme.bgPrimary,
      appBar: AppBar(
        title: Text('Privacy Policy', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: MehdAiTheme.bgSecondary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Text(
          '''MEHD AI — PRIVACY POLICY
Last updated: March 2026

1. WHAT WE COLLECT
- Account registration data (email, username)
- Trading analysis history (symbols searched, consensus results)
- Paper trading performance metrics
- Device and connection quality metadata

2. WHAT WE DO NOT COLLECT
- Broker login credentials (these are stored locally on your device only)
- Credit card information (processed by Stripe, never stored)
- Real trading account balances or positions

3. HOW WE USE YOUR DATA
- To provide the AI consensus analysis service
- To improve the Den's accuracy via Alpha Snapshots (anonymised)
- To enforce paper trading safety requirements
- To generate your personal Journey analytics

4. DATA STORAGE
All data is encrypted at rest and in transit. User profiles are stored in Firebase with end-to-end encryption. Alpha Snapshots are anonymised before storage.

5. THIRD-PARTY SHARING
We do not sell or share your personal data with third parties. AI model APIs (OpenAI, Anthropic, etc.) receive only market data snapshots, never personal information.

6. YOUR RIGHTS
You may request deletion of your account and all associated data at any time by contacting support@mehd.ai.

7. COOKIES
The web version uses essential cookies only for session management. No tracking cookies are used.
''',
          style: MehdAiTheme.terminalStyle.copyWith(
            fontSize: 12,
            height: 1.6,
            color: MehdAiTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
