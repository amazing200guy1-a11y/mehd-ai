import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, SharedPreferences? prefs});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _bgCtrl;
  late AnimationController _logoCtrl;
  late AnimationController _glowCtrl;
  late Animation<double> _bgFade;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _glow;

  String _typed = '';
  String _tagline = '';
  final _title = 'MEHD AI';
  final _sub = 'Capital is a seed, not a sacrifice';
  Timer? _t1, _t2;

  @override
  void initState() {
    super.initState();

    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500));
    _bgFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _bgCtrl, curve: Curves.easeIn));

    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200));
    _logoScale = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut));
    _logoFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _logoCtrl, curve: const Interval(0, 0.4, curve: Curves.easeIn)));

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
    _glow = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));

    _runSequence();
  }

  Future _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    _bgCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    _logoCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    // Type title
    int i = 0;
    _t1 = Timer.periodic(const Duration(milliseconds: 90), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        if (i < _title.length) {
          _typed += _title[i++];
        } else {
          t.cancel();
          _typeTagline();
        }
      });
    });
  }

  void _typeTagline() {
    int i = 0;
    _t2 = Timer.periodic(const Duration(milliseconds: 30), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        if (i < _sub.length) {
          _tagline += _sub[i++];
        } else {
          t.cancel();
          Future.delayed(const Duration(milliseconds: 800), _navigate);
        }
      });
    });
  }

  Future _navigate() async {
    if (!mounted) return;
    final p = await SharedPreferences.getInstance();
    final done = p.getBool('onboarding_complete') ?? false;
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
    _bgCtrl.dispose();
    _logoCtrl.dispose();
    _glowCtrl.dispose();
    _t1?.cancel();
    _t2?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: AnimatedBuilder(
        animation: Listenable.merge([_bgFade, _logoScale, _logoFade, _glow]),
        builder: (_, __) => Stack(
          children: [
            // Radial blue glow background
            Positioned.fill(
              child: Opacity(
                opacity: _bgFade.value * 0.2,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 0.6,
                      colors: [
                        Color(0xFF58A6FF),
                        Colors.transparent,
                      ]
                    )
                  )
                )
              )
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // TIGER LOGO — animated
                  Opacity(
                    opacity: _logoFade.value,
                    child: Transform.scale(
                      scale: _logoScale.value,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF58A6FF).withOpacity(_glow.value * 0.6),
                              blurRadius: 50,
                              spreadRadius: 15),
                            BoxShadow(
                              color: const Color(0xFF58A6FF).withOpacity(_glow.value * 0.3),
                              blurRadius: 100,
                              spreadRadius: 30),
                          ]),
                        child: Image.asset(
                          'assets/images/mehd_logo.png',
                          width: 120,
                          height: 120,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF58A6FF),
                                width: 2)),
                            child: const Center(
                              child: Text('🐯', style: TextStyle(fontSize: 64))
                            )
                          )
                        )
                      )
                    )
                  ),
                  const SizedBox(height: 40),

                  // TYPEWRITER TITLE
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: _typed.characters
                      .map((c) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1),
                        child: Text(c,
                          style: const TextStyle(
                            color: Color(0xFF58A6FF),
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4))))
                      .toList()),

                  const SizedBox(height: 10),

                  // TAGLINE
                  Text(_tagline,
                    style: const TextStyle(
                      color: Color(0xFF888888), // Adjusted for readability if background is black
                      fontSize: 11,
                      letterSpacing: 1),
                    textAlign: TextAlign.center),

                  const SizedBox(height: 50),

                  // Loading
                  if (_typed.length >= _title.length)
                    Column(children: [
                      SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 0.8,
                          color: const Color(0xFF58A6FF).withOpacity(0.3))),
                      const SizedBox(height: 8),
                      const Text(
                        'SYNCHRONIZING KERNEL...',
                        style: TextStyle(
                          color: Color(0xFF888888), // Adjusted for dark background
                          fontSize: 7,
                          letterSpacing: 2)),
                    ]),
                ]
              )
            ),
          ]
        )
      ),
    );
  }
}
