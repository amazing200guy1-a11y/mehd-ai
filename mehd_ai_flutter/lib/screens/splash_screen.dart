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
        _navigate();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.forward();
    });
  }

  void _navigate() async {
    final prefs = await SharedPreferences.getInstance();
    final done = prefs.getBool('onboarding_complete') ?? false;
    final user = FirebaseAuth.instance.currentUser;
    if (!mounted) return;
    
    if (user != null) {
      Navigator.pushReplacementNamed(context, '/home');
    } else if (!done) {
      Navigator.pushReplacementNamed(context, '/onboarding');
    } else {
      Navigator.pushReplacementNamed(context, '/auth');
    }
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🐯', style: TextStyle(fontSize: 80)),
            const SizedBox(height: 28),
            const Text(
              'THE DEN',
              style: TextStyle(
                color: Color(0xFF1A1A1A),
                fontSize: 20,
                letterSpacing: 8,
                fontFamily: 'Courier New',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Capital is a seed, not a sacrifice',
              style: TextStyle(
                color: Color(0xFF0D0D0D),
                fontSize: 10,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
