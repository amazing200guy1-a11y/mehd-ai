import 'package:flutter/material.dart';
import 'package:mehd_ai_flutter/core/theme.dart';
import 'package:mehd_ai_flutter/screens/auth/login_screen.dart';
import 'package:mehd_ai_flutter/screens/auth/register_screen.dart';

/// FILE 4 — welcome_screen.dart
///
/// Build Debrief:
/// The Welcome Screen is the first impression for new users. In fintech, trust
/// is built in 3 seconds — the dark, clean aesthetic with the pulsing cursor
/// immediately signals "this is a professional trading tool, not a toy."
///
/// The tagline "Your money. Protected by 11 AIs." is the entire value prop in
/// one line. The paper trading callout at the bottom removes fear — new users
/// can explore without risking real money. This converts sign-ups.

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Fade-in animation for the entire screen content
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    // Pulsing cursor animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Start fade-in after a brief delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),

                // ── LOGO ──────────────────────────────────────────
                Column(
                  children: [
                    FadeTransition(
                      opacity: _pulseAnimation,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF58A6FF).withOpacity(0.3),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF58A6FF).withOpacity(0.15),
                              blurRadius: 20,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/mehd_logo.png',
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'MEHD AI',
                      style: MehdAiTheme.headingStyle.copyWith(
                        fontSize: 36,
                        letterSpacing: 8.0,
                        fontWeight: FontWeight.w700,
                        color: MehdAiTheme.textPrimary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── TAGLINE ───────────────────────────────────────
                Text(
                  '11 agents. 3 layers. One Den. Your money protected by The Don.',
                  style: MehdAiTheme.labelStyle.copyWith(
                    fontSize: 14,
                    color: MehdAiTheme.textSecondary,
                    letterSpacing: 1.0,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 60),

                // ── CREATE ACCOUNT BUTTON ─────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const RegisterScreen(),
                      ));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MehdAiTheme.green,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Create Account',
                      style: MehdAiTheme.headingStyle.copyWith(
                        fontSize: 16,
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // ── SIGN IN BUTTON ────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const LoginScreen(),
                      ));
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: MehdAiTheme.textPrimary,
                      side: const BorderSide(color: MehdAiTheme.borderColor),
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Sign In',
                      style: MehdAiTheme.headingStyle.copyWith(
                        fontSize: 16,
                        color: MehdAiTheme.textPrimary,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // ── PAPER TRADING NOTICE ──────────────────────────
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: MehdAiTheme.green.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: MehdAiTheme.green.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shield_outlined,
                          size: 16, color: MehdAiTheme.green.withOpacity(0.7)),
                      const SizedBox(width: 8),
                      Text(
                        'Paper trading mode — no real money needed to start',
                        style: MehdAiTheme.labelStyle.copyWith(
                          color: MehdAiTheme.green.withOpacity(0.8),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
            ),
          ),
        ),

      ),
    );
  }
}
