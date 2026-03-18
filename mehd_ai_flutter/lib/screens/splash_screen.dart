import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mehd_ai_flutter/core/theme.dart';
import 'package:mehd_ai_flutter/services/auth_service.dart';
import 'package:mehd_ai_flutter/screens/home_screen.dart';
import 'package:mehd_ai_flutter/screens/auth/login_screen.dart';
import 'package:mehd_ai_flutter/screens/onboarding/broker_connect_screen.dart';
import 'package:provider/provider.dart';

/// FILE — splash_screen.dart
///
/// Build Debrief: VS Code style aesthetic. Pure #0D1117 background.
/// Faded 0.08 watermark logo. Muted "MEHD AI" text.
/// Blinking cursor like a terminal. No loading bars. Silence.

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _cursorController;
  late Animation<double> _cursorFade;
  bool _isDisposed = false;
  double _globalOpacity = 1.0;

  @override
  void initState() {
    super.initState();
    // 1-second cursor blink cycle
    _cursorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
    
    // Instead of smooth pulsing fade, we want it to blink on/off like a terminal cursor
    // so we use a StepTween or just harsh thresholds on the transition, but a fast fade
    // simulating a monitor cursor is typical.
    _cursorFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cursorController, curve: Curves.linear),
    );

    // After 2.5 seconds exactly, we fade out then navigate.
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() => _globalOpacity = 0.0);
        // The fade out takes 400ms, wait for it then navigate
        Future.delayed(const Duration(milliseconds: 400), _navigate);
      }
    });
  }

  void _navigate() {
    if (_isDisposed) return;
    final authService = context.read<AuthService>();

    if (!authService.isLoggedIn) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: Duration.zero,
          pageBuilder: (_, __, ___) => const LoginScreen(),
        ),
      );
      return;
    }

    final profile = authService.userProfile;
    if (profile == null || !profile.onboardingComplete) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: Duration.zero,
          pageBuilder: (_, __, ___) => const BrokerConnectScreen(),
        ),
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: Duration.zero,
        pageBuilder: (_, __, ___) => const HomeScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _cursorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MehdAiTheme.bgPrimary, // #0D1117
      body: AnimatedOpacity(
        opacity: _globalOpacity,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 260x260 Tiger Logo Watermark, opacity 0.10
              Opacity(
                opacity: 0.10,
                child: Image.asset(
                  'assets/images/mehd_logo.png',
                  width: 260,
                  height: 260,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 32),
              // Muted Title
              Text(
                'MEHD AI',
                style: GoogleFonts.jetBrainsMono(
                  color: const Color(0xFF3B4048), // Barely visible muted grey
                  fontSize: 16,
                  letterSpacing: 10.0,
                  fontWeight: FontWeight.normal,
                ),
              ),
              const SizedBox(height: 16),
              // Blinking Cursor
              AnimatedBuilder(
                animation: _cursorFade,
                builder: (context, child) {
                  // Make it a hard blink rather than a slow fade
                  final isVisible = _cursorFade.value > 0.5;
                  return Opacity(
                    opacity: isVisible ? 1.0 : 0.0,
                    child: Container(
                      width: 8,
                      height: 16,
                      color: const Color(0xFF58A6FF), // Blue cursor
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
