import 'package:flutter/material.dart';
import 'package:mehd_ai_flutter/core/theme.dart';
import 'package:mehd_ai_flutter/services/auth_service.dart';
import 'package:mehd_ai_flutter/services/settings_service.dart';
import 'package:mehd_ai_flutter/services/user_service.dart';
import 'package:provider/provider.dart';

/// FILE 7 — risk_setup_screen.dart
///
/// The slider now allows 0.1% – 10% risk per trade.
/// Colour coding:
///   Green  = 0.1–2%   (conservative, recommended for beginners)
///   Yellow = 2.1–5%   (moderate, experienced traders)
///   Red    = 5.1–10%  (aggressive, professionals only)
/// The value is saved to Firestore AND to SettingsService globally.
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
    final settingsService = context.read<SettingsService>();
    final userService = UserService();
    final userId = authService.currentUser?.uid;

    if (userId != null) {
      try {
        await userService.updateRiskSettings(userId, _riskPercent);
      } catch (e) {
        debugPrint('Risk save error: $e');
      }
    }
    
    // Also sync to the global in-memory SettingsService
    await settingsService.setRiskPerTrade(_riskPercent);

    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/tutorial');
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
                        color: _riskPercent <= 2.0
                            ? MehdAiTheme.green
                            : _riskPercent <= 5.0
                                ? MehdAiTheme.yellow
                                : MehdAiTheme.red,
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
                        activeTrackColor: _riskPercent <= 2.0
                            ? MehdAiTheme.green
                            : _riskPercent <= 5.0
                                ? MehdAiTheme.yellow
                                : MehdAiTheme.red,
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
                        max: 10.0,
                        divisions: 99,
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
                          Text('0.1% Safe',
                              style: MehdAiTheme.labelStyle.copyWith(
                                fontSize: 11, color: MehdAiTheme.green)),
                          Text(_riskPercent > 5.0 ? '⚠ HIGH RISK' : _riskPercent > 2.0 ? 'Moderate' : 'Conservative',
                              style: MehdAiTheme.labelStyle.copyWith(
                                fontSize: 11,
                                color: _riskPercent > 5.0 ? MehdAiTheme.red : _riskPercent > 2.0 ? MehdAiTheme.yellow : MehdAiTheme.green,
                                fontWeight: FontWeight.w600,
                              )),
                          Text('10.0% Pro',
                              style: MehdAiTheme.labelStyle.copyWith(
                                fontSize: 11, color: MehdAiTheme.red)),
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
