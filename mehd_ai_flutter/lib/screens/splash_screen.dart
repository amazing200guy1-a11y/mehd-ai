import 'package:flutter/material.dart';
import 'package:mehd_ai_flutter/services/auth_service.dart';
import 'package:mehd_ai_flutter/screens/home_screen.dart';
import 'package:mehd_ai_flutter/screens/auth_screen.dart';
import 'package:mehd_ai_flutter/screens/onboarding_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  final SharedPreferences prefs;
  const SplashScreen({super.key, required this.prefs});
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
  
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000), // Extended for grandness
    );

    // Logo scale and fade (0.0 to 0.4)
    _tigerScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.4, curve: Curves.easeOutBack)),
    );
    _tigerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.4, curve: Curves.easeOut)),
    );

    // Typing animation (0.4 to 0.7)
    _typingAnim = IntTween(begin: 0, end: 7).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.4, 0.7, curve: Curves.linear)),
    );
    _typingColor = ColorTween(begin: const Color(0xFF003D80), end: const Color(0xFF58A6FF)).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.4, 0.7, curve: Curves.easeOut)),
    );

    // Tagline fade (0.7 to 0.9)
    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.7, 0.9, curve: Curves.easeIn)),
    );

    // Cursor blink (0.7 to 1.0)
    _cursorFade = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 30),
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 40),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.7, 1.0, curve: Curves.linear)));

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigate();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.forward();
    });
  }

  void _navigate() async {
    if (!mounted || _isDisposed) return;

    final done = widget.prefs.getBool('onboarding_complete') ?? false;
    
    if (!mounted) return;
    
    // Use AuthService from Provider instead of raw FirebaseAuth
    final authService = context.read<AuthService>();
    final isLoggedIn = authService.isLoggedIn;
    
    if (!mounted) return;
    
    Widget nextPage;
    if (isLoggedIn) {
      nextPage = const HomeScreen();
    } else if (!done) {
      nextPage = const OnboardingScreen();
    } else {
      nextPage = const AuthScreen();
    }
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => nextPage),
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
      backgroundColor: const Color(0xFF000000),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final typedText = 'MEHD AI'.substring(0, _typingAnim.value);
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Tiger with scale + fade
                Transform.scale(
                  scale: _tigerScale.value,
                  child: Opacity(
                    opacity: _tigerFade.value,
                    child: Hero(
                      tag: 'tigerLogo',
                      child: Image.asset(
                        'assets/images/mehd_logo.png',
                        width: 140, // Perfect size for splash screen
                        errorBuilder: (_, __, ___) => const Text('🐯', style: TextStyle(fontSize: 80)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                // Typing animation for "THE DEN"
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      typedText,
                      style: TextStyle(
                        color: _typingColor.value,
                        fontSize: 22,
                        letterSpacing: 8,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          BoxShadow(
                            color: const Color(0xFF58A6FF).withOpacity(0.3 * _taglineFade.value),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                    ),
                    // Blinking cursor
                    Opacity(
                      opacity: _cursorFade.value,
                      child: Text(
                        '▌',
                        style: TextStyle(
                          color: const Color(0xFF58A6FF),
                          fontSize: 22,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Tagline fade-in
                Opacity(
                  opacity: _taglineFade.value,
                  child: const Text(
                    'SYNCHRONIZING KERNEL...',
                    style: TextStyle(
                      color: Color(0xFF888888),
                      fontSize: 11,
                      letterSpacing: 3,
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
