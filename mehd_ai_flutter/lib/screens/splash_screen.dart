import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mehd_ai_flutter/core/theme.dart';
import 'package:mehd_ai_flutter/services/auth_service.dart';
import 'package:mehd_ai_flutter/screens/home_screen.dart';
import 'package:mehd_ai_flutter/screens/auth_screen.dart';
import 'package:mehd_ai_flutter/screens/onboarding_screen.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  late Animation<double> _tigerScale;
  late Animation<double> _tigerFade;
  late Animation<int> _typingAnim;
  late Animation<Color?> _typingColor;
  late Animation<double> _taglineFade;
  late Animation<double> _cursorFade;
  
  Widget? _nextPage;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // 0.3s - 1.0s (12% to 40%)
    _tigerScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.12, 0.40, curve: Curves.easeOutBack)),
    );
    _tigerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.12, 0.40, curve: Curves.easeOut)),
    );

    // 1.0s - 1.8s (40% to 72%)
    // 7 letters taking 560ms out of 2500ms = 22.4% (from 40% to 62.4%)
    _typingAnim = IntTween(begin: 0, end: 7).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.40, 0.624, curve: Curves.linear)),
    );
    _typingColor = ColorTween(begin: const Color(0xFF1A1A1A), end: const Color(0xFF2A2A2A)).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.40, 0.72, curve: Curves.linear)),
    );

    // 1.8s - 2.2s (72% to 88%)
    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.72, 0.88, curve: Curves.easeIn)),
    );

    // 2.2s - 2.5s (88% to 100%) - Blink once (visible -> hidden -> visible -> hidden)
    _cursorFade = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 30),
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 40),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.88, 1.0, curve: Curves.linear)));

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _dispatch();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resolveRoute();
      _controller.forward();
    });
  }

  Future<void> _resolveRoute() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    // Ensure firebase is initialized
    await authService.ensureFirebaseReady();
    
    final prefs = authService.prefs;
    final onboardingDone = prefs.getBool('onboarding_complete') ?? false;
    final user = authService.immediateCurrentUser;

    if (user != null) {
      _nextPage = const HomeScreen();
    } else if (!onboardingDone) {
      _nextPage = const OnboardingScreen();
    } else {
      _nextPage = const AuthScreen();
    }
  }

  void _dispatch() async {
    if (_isDisposed || !mounted) return;
    
    // Fallback if auth is still parsing
    while (_nextPage == null) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    if (_isDisposed || !mounted) return;
    
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => _nextPage!,
        transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000), // Pure Black Specification
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final textStr = "THE DEN".substring(0, _typingAnim.value);
          
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Tiger Logo Fade & Scale
                Opacity(
                  opacity: _tigerFade.value,
                  child: Transform.scale(
                    scale: _tigerScale.value,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Image.asset(
                          'assets/images/mehd_logo.png',
                          width: 200,
                          height: 200,
                          fit: BoxFit.contain,
                        ),
                        // Simulated glowing eye pulse via shader mask scaling
                        if (_controller.value > 0.12 && _controller.value < 0.50)
                          Opacity(
                            opacity: (_tigerScale.value - 0.8) * 5.0, // Pulsing effect that fades
                            child: ShaderMask(
                              shaderCallback: (rect) => RadialGradient(
                                center: const Alignment(0, -0.2),
                                radius: 0.15,
                                colors: [Colors.blue.withOpacity(0.8), Colors.transparent],
                              ).createShader(rect),
                              blendMode: BlendMode.srcATop,
                              child: Image.asset(
                                'assets/images/mehd_logo.png',
                                width: 200,
                                height: 200,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // THE DEN text + Cursor
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      textStr,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 18,
                        letterSpacing: 8.0,
                        fontWeight: FontWeight.bold,
                        color: _typingColor.value,
                      ),
                    ),
                    if (_controller.value >= 0.4)
                      Opacity(
                        opacity: _controller.value >= 0.88 ? _cursorFade.value : 1.0,
                        child: Container(
                          width: 8,
                          height: 18,
                          margin: const EdgeInsets.only(left: 4),
                          color: MehdAiTheme.blue,
                        ),
                      )
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Tagline Fade
                Opacity(
                  opacity: _taglineFade.value,
                  child: Text(
                    "Capital is a seed, not a sacrifice",
                    style: GoogleFonts.jetBrainsMono(
                      color: const Color(0xFF111111),
                      fontSize: 9,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
