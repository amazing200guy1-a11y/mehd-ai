import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mehd_ai_flutter/screens/auth_screen.dart';
import 'package:mehd_ai_flutter/screens/home_screen.dart';
import 'package:mehd_ai_flutter/screens/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  final SharedPreferences? prefs;
  const SplashScreen({super.key, this.prefs});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  
  // Animation controllers
  late AnimationController _bgCtrl;
  late AnimationController _logoCtrl;
  late AnimationController _glowCtrl;
  late AnimationController _textCtrl;
  late AnimationController _pulseCtrl;
  
  // Animations
  late Animation<double> _bgAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _glowAnim;
  late Animation<double> _textAnim;
  late Animation<double> _pulseAnim;
  
  // Text reveal
  final String _title = 'MEHD AI';
  int _visibleChars = 0;
  Timer? _typeTimer;
  
  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startSequence();
  }
  
  void _setupAnimations() {
    // Background glow
    _bgCtrl = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this);
    _bgAnim = Tween<double>(
      begin: 0.0, end: 1.0)
      .animate(CurvedAnimation(
        parent: _bgCtrl,
        curve: Curves.easeIn));
    
    // Logo scale (hero entrance)
    _logoCtrl = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this);
    _scaleAnim = Tween<double>(
      begin: 0.0, end: 1.0)
      .animate(CurvedAnimation(
        parent: _logoCtrl,
        curve: Curves.elasticOut));
    _fadeAnim = Tween<double>(
      begin: 0.0, end: 1.0)
      .animate(CurvedAnimation(
        parent: _logoCtrl,
        curve: const Interval(0.0, 0.5,
          curve: Curves.easeIn)));
    
    // Glow pulse (continuous)
    _glowCtrl = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this)..repeat(reverse: true);
    _glowAnim = Tween<double>(
      begin: 0.3, end: 1.0)
      .animate(CurvedAnimation(
        parent: _glowCtrl,
        curve: Curves.easeInOut));
    
    // Text reveal
    _textCtrl = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this);
    _textAnim = Tween<double>(
      begin: 0.0, end: 1.0)
      .animate(CurvedAnimation(
        parent: _textCtrl,
        curve: Curves.easeOut));
    
    // Subtle continuous pulse
    _pulseCtrl = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this)..repeat(reverse: true);
    _pulseAnim = Tween<double>(
      begin: 0.95, end: 1.05)
      .animate(CurvedAnimation(
        parent: _pulseCtrl,
        curve: Curves.easeInOut));
  }
  
  void _startSequence() async {
    // Scene 1: Darkness (500ms)
    await Future.delayed(
      const Duration(milliseconds: 500));
    if (!mounted) return;
    
    // Scene 2: Background glow
    _bgCtrl.forward();
    await Future.delayed(
      const Duration(milliseconds: 600));
    if (!mounted) return;
    
    // Scene 3: Tiger emerges
    _logoCtrl.forward();
    await Future.delayed(
      const Duration(milliseconds: 800));
    if (!mounted) return;
    
    // Scene 4: Title types
    _textCtrl.forward();
    _typeTimer = Timer.periodic(
      const Duration(milliseconds: 100), (t) {
      if (!mounted) {
        t.cancel(); return;
      }
      setState(() {
        if (_visibleChars < _title.length) {
          _visibleChars++;
        } else {
          t.cancel();
        }
      });
    });
    
    // Scene 5: Wait then navigate
    await Future.delayed(
      const Duration(milliseconds: 2000));
    if (!mounted) return;
    _navigate();
  }
  
  void _navigate() async {
    final prefs = widget.prefs ?? await
      SharedPreferences.getInstance();
    final done = prefs.getBool(
      'onboarding_complete') ?? false;
      
    User? user;
    try {
      user = FirebaseAuth.instance.currentUser;
    } catch (_) {}
    
    if (!mounted) return;
    
    if (user != null) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else if (!done) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const OnboardingScreen()));
    } else {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AuthScreen()));
    }
  }
  
  @override
  void dispose() {
    _bgCtrl.dispose();
    _logoCtrl.dispose();
    _glowCtrl.dispose();
    _textCtrl.dispose();
    _pulseCtrl.dispose();
    _typeTimer?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _bgAnim, _scaleAnim, _fadeAnim,
          _glowAnim, _textAnim, _pulseAnim,
        ]),
        builder: (context, _) {
          return Stack(children: [
            
            // BACKGROUND RADIAL GLOW
            // Emerges from center like sunrise
            Positioned.fill(
              child: Opacity(
                opacity: _bgAnim.value * 0.15,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 0.8,
                      colors: [
                        Color(0xFF58A6FF),
                        Color(0xFF000000),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // MAIN CONTENT
            Center(
              child: Column(
                mainAxisAlignment:
                  MainAxisAlignment.center,
                children: [
                  
                  // TIGER LOGO with glow
                  Opacity(
                    opacity: _fadeAnim.value,
                    child: Transform.scale(
                      scale: _scaleAnim.value
                        * _pulseAnim.value,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF58A6FF)
                                .withOpacity(
                                  _glowAnim.value
                                  * 0.5),
                              blurRadius: 40,
                              spreadRadius: 10),
                            BoxShadow(
                              color: const Color(
                                0xFF58A6FF)
                                .withOpacity(
                                  _glowAnim.value
                                  * 0.2),
                              blurRadius: 80,
                              spreadRadius: 20),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/mehd_logo.png',
                          width: 120,
                          height: 120),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 36),
                  
                  // TYPEWRITER TITLE
                  FadeTransition(
                    opacity: _textAnim,
                    child: Row(
                      mainAxisAlignment:
                        MainAxisAlignment.center,
                      children: List.generate(
                        _visibleChars, (i) =>
                        AnimatedOpacity(
                          opacity: 1.0,
                          duration: const Duration(
                            milliseconds: 100),
                          child: Text(
                            _title[i],
                            style: const TextStyle(
                              color: Color(
                                0xFF58A6FF),
                              fontSize: 28,
                              fontWeight:
                                FontWeight.bold,
                              letterSpacing: 8),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 10),
                  
                  // TAGLINE
                  AnimatedOpacity(
                    opacity: _visibleChars >=
                      _title.length ? 1.0 : 0.0,
                    duration: const Duration(
                      milliseconds: 500),
                    child: const Text(
                      'Capital is a seed, '
                      'not a sacrifice',
                      style: TextStyle(
                        color: Color(0xFF555555),
                        fontSize: 11,
                        letterSpacing: 1.5),
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // LOADING INDICATOR
                  AnimatedOpacity(
                    opacity: _visibleChars >=
                      _title.length ? 1.0 : 0.0,
                    duration: const Duration(
                      milliseconds: 500),
                    child: Column(children: [
                      SizedBox(
                        width: 20, height: 20,
                        child:
                          CircularProgressIndicator(
                            strokeWidth: 1.0,
                            color: const Color(0xFF58A6FF)
                              .withOpacity(0.3))),
                      const SizedBox(height: 10),
                      const Text(
                        'SYNCHRONIZING KERNEL...',
                        style: TextStyle(
                          color: Color(0xFF444444),
                          fontSize: 8,
                          letterSpacing: 2)),
                    ]),
                  ),
                ],
              ),
            ),
          ]);
        },
      ),
    );
  }
}
