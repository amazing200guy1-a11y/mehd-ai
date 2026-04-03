import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mehd_ai_flutter/core/theme.dart';

/// FIX 3: Legal onboarding screen with 6 mandatory checkboxes.
/// All boxes must be checked before the user can proceed.

class LegalScreen extends StatefulWidget {
  final VoidCallback onAccepted;
  const LegalScreen({super.key, required this.onAccepted});

  @override
  State<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends State<LegalScreen> {
  final List<bool> _checks = List.filled(6, false);

  static const List<String> _labels = [
    'I understand this is NOT financial advice',
    'I understand AI analysis can be wrong',
    'I accept full responsibility for my trades',
    'I am legally allowed to trade forex in my country',
    'I will start with paper trading before using real money',
    'I understand past performance does not guarantee future results',
  ];

  bool get _allChecked => _checks.every((c) => c);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MehdAiTheme.bgPrimary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              Text(
                'IMPORTANT LEGAL NOTICE',
                style: GoogleFonts.jetBrainsMono(
                  color: MehdAiTheme.red,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Mehd AI is an educational tool that uses artificial intelligence '
                'to analyze market data.\n\nBy continuing you confirm:',
                style: MehdAiTheme.labelStyle.copyWith(fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  itemCount: _labels.length,
                  itemBuilder: (context, index) {
                    return CheckboxListTile(
                      value: _checks[index],
                      onChanged: (val) => setState(() => _checks[index] = val ?? false),
                      title: Text(
                        _labels[index],
                        style: MehdAiTheme.terminalStyle.copyWith(
                          fontSize: 13,
                          color: _checks[index] ? MehdAiTheme.green : MehdAiTheme.textPrimary,
                        ),
                      ),
                      activeColor: MehdAiTheme.green,
                      checkColor: Colors.black,
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'All boxes must be checked before proceeding. '
                'This confirmation is logged to your account permanently.',
                style: MehdAiTheme.labelStyle.copyWith(fontSize: 11),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _allChecked ? widget.onAccepted : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _allChecked ? MehdAiTheme.green : const Color(0xFF30363D),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    _allChecked ? 'I ACCEPT — CONTINUE' : 'CHECK ALL BOXES TO CONTINUE',
                    style: MehdAiTheme.terminalStyle.copyWith(
                      color: _allChecked ? Colors.black : MehdAiTheme.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
