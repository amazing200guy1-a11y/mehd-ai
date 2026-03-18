import 'package:flutter/material.dart';
import 'package:mehd_ai_flutter/core/theme.dart';
import 'package:mehd_ai_flutter/services/auth_service.dart';
import 'package:mehd_ai_flutter/services/user_service.dart';
import 'package:mehd_ai_flutter/screens/onboarding/tutorial_screen.dart';
import 'package:provider/provider.dart';

/// FILE 7 — risk_setup_screen.dart
///
/// Build Debrief:
/// This is the most important screen in the entire onboarding flow. It forces
/// users to consciously acknowledge the risk rules BEFORE they can trade.
///
/// The slider is HARD-CAPPED at 1.0% — this isn't a suggestion, it's the law
/// of the app. The cap is enforced at 3 levels:
///   1. The Flutter slider physically cannot go above 1.0%
///   2. The UserService clamps the value in Dart before saving
///   3. Firestore security rules reject any write > 1.0
///
/// The kill-switch card is shown but cannot be disabled — it's informational.
/// Users need to know it exists so they trust the system, but they shouldn't
/// be able to turn it off because the entire safety architecture depends on it.
///
/// The real-time dollar calculation ("$10 on a $1,000 account") makes abstract
/// percentages concrete. Traders understand "$10" much better than "1%".

class RiskSetupScreen extends StatefulWidget {
  const RiskSetupScreen({super.key});

  @override
  State<RiskSetupScreen> createState() => _RiskSetupScreenState();
}

class _RiskSetupScreenState extends State<RiskSetupScreen> {
  double _riskPercent = 1.0;
  final double _demoBalance = 1000.0; // Used for the dollar preview
  bool _isLoading = false;

  Future<void> _saveAndContinue() async {
    setState(() => _isLoading = true);

    final authService = context.read<AuthService>();
    final userService = UserService();
    final userId = authService.currentUser?.uid;

    if (userId != null) {
      try {
        await userService.updateRiskSettings(userId, _riskPercent);
      } catch (e) {
        debugPrint('Risk save error: $e');
      }
    }

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const TutorialScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxLossAmount = (_demoBalance * _riskPercent / 100);

    return Scaffold(
      backgroundColor: MehdAiTheme.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Step 2 of 3',
          style: MehdAiTheme.labelStyle.copyWith(fontSize: 13),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // ── HEADING ───────────────────────────────────
              Icon(
                Icons.shield,
                color: MehdAiTheme.green,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Protect Your Capital',
                style: MehdAiTheme.headingStyle.copyWith(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'The Risk Kernel enforces these rules.\nNo AI can override them.',
                style: MehdAiTheme.labelStyle.copyWith(
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // ── RISK PERCENTAGE DISPLAY ────────────────────
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  color: MehdAiTheme.bgSecondary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: MehdAiTheme.borderColor),
                ),
                child: Column(
                  children: [
                    Text(
                      'RISK PER TRADE',
                      style: MehdAiTheme.labelStyle.copyWith(
                        fontSize: 11,
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Big percentage display
                    Text(
                      '${_riskPercent.toStringAsFixed(1)}%',
                      style: MehdAiTheme.priceStyle.copyWith(
                        fontSize: 56,
                        color: _riskPercent <= 0.5
                            ? MehdAiTheme.green
                            : MehdAiTheme.yellow,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Dollar amount preview — updates in real time
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: MehdAiTheme.bgTertiary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'On a \$${_demoBalance.toInt()} account, max loss per trade = \$${maxLossAmount.toStringAsFixed(2)}',
                        style: MehdAiTheme.terminalStyle.copyWith(
                          fontSize: 12,
                          color: MehdAiTheme.textSecondary,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── SLIDER — HARD-CAPPED AT 1.0% ────────
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: _riskPercent <= 0.5
                            ? MehdAiTheme.green
                            : MehdAiTheme.yellow,
                        inactiveTrackColor:
                            MehdAiTheme.borderColor.withOpacity(0.3),
                        thumbColor: MehdAiTheme.textPrimary,
                        overlayColor: MehdAiTheme.blue.withOpacity(0.1),
                        trackHeight: 6,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 10,
                        ),
                      ),
                      child: Slider(
                        value: _riskPercent,
                        min: 0.1,
                        max: 1.0, // HARD STOP at 1% — CANNOT go higher
                        divisions: 9,
                        onChanged: (value) {
                          setState(() {
                            _riskPercent = double.parse(value.toStringAsFixed(1));
                          });
                        },
                      ),
                    ),

                    // Slider labels
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('0.1%',
                              style: MehdAiTheme.labelStyle
                                  .copyWith(fontSize: 11)),
                          Text('1.0% MAX',
                              style: MehdAiTheme.labelStyle.copyWith(
                                fontSize: 11,
                                color: MehdAiTheme.yellow,
                                fontWeight: FontWeight.w600,
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── KILL SWITCH CARD ──────────────────────────
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: MehdAiTheme.red.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: MehdAiTheme.red.withOpacity(0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.emergency,
                        color: MehdAiTheme.red.withOpacity(0.8), size: 22),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kill Switch — Always Active',
                            style: MehdAiTheme.headingStyle.copyWith(
                              fontSize: 14,
                              color: MehdAiTheme.red,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'If your account loses 3% in one day, Mehd AI locks trading for 24 hours automatically.',
                            style: MehdAiTheme.labelStyle.copyWith(
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: MehdAiTheme.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Cannot be disabled',
                              style: MehdAiTheme.labelStyle.copyWith(
                                fontSize: 10,
                                color: MehdAiTheme.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── KERNEL ENFORCEMENT TEXT ────────────────────
              Text(
                'These rules are enforced at the kernel level.\nNot even the AI can override them.',
                style: MehdAiTheme.labelStyle.copyWith(
                  fontSize: 13,
                  color: MehdAiTheme.purple,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // ── AGREE BUTTON ──────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveAndContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MehdAiTheme.green,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 22,
                          width: 22,
                          child: Opacity(opacity: 0.5, child: Image.asset('assets/images/mehd_logo.png')),
                        )
                      : Text(
                          'I understand and agree',
                          style: MehdAiTheme.headingStyle.copyWith(
                            fontSize: 16,
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
