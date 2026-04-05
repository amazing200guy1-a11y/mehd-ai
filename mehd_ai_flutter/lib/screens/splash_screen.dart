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
      duration: const Duration(milliseconds: 800),
    );


    // 0.1s - 0.4s (8.3% to 33%)
    _tigerScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.08, 0.33, curve: Curves.easeOutBack)),
    );
    _tigerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.08, 0.33, curve: Curves.easeOut)),
    );

    // 0.4s - 1.0s (33% to 83%)
    _typingAnim = IntTween(begin: 0, end: 7).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.33, 0.65, curve: Curves.linear)),
    );
    _typingColor = ColorTween(begin: const Color(0xFF1A1A1A), end: const Color(0xFF2A2A2A)).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.33, 0.83, curve: Curves.linear)),
    );

    // 1.0s - 1.1s (83% to 91.6%)
    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.83, 0.916, curve: Curves.easeIn)),
    );

    // 1.1s - 1.2s (91.6% to 100%)
    _cursorFade = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 30),
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 40),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.916, 1.0, curve: Curves.linear)));

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
          final typedText = 'THE DEN'.substring(0, _typingAnim.value);
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Tiger with scale + fade
                Transform.scale(
                  scale: _tigerScale.value,
                  child: Opacity(
                    opacity: _tigerFade.value,
                    child: const Text('🐯', style: TextStyle(fontSize: 80)),
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
                        fontSize: 20,
                        letterSpacing: 8,
                        fontFamily: 'Courier New',
                      ),
                    ),
                    // Blinking cursor
                    Opacity(
                      opacity: _cursorFade.value,
                      child: Text(
                        '▌',
                        style: TextStyle(
                          color: _typingColor.value,
                          fontSize: 20,
                          fontFamily: 'Courier New',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Tagline fade-in
                Opacity(
                  opacity: _taglineFade.value,
                  child: const Text(
                    'Capital is a seed, not a sacrifice',
                    style: TextStyle(
                      color: Color(0xFF0D0D0D),
                      fontSize: 10,
                      letterSpacing: 2,
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
