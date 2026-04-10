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
  late AnimationController _scaleCtrl;
  late AnimationController _glowCtrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _glowAnim;
  
  @override
  void initState() {
    super.initState();
    
    _scaleCtrl = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this);
    
    _glowCtrl = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this)..repeat(reverse: true);
    
    _scaleAnim = Tween<double>(
      begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _scaleCtrl,
        curve: Curves.easeOutBack));
    
    _glowAnim = Tween<double>(
      begin: 0.2, end: 0.8).animate(
      _glowCtrl);
    
    _scaleCtrl.forward();
    
    Future.delayed(
      const Duration(milliseconds: 500),
      _navigate);
  }
  
  void _navigate() async {
    if (!mounted) return;
    final p = widget.prefs ?? await SharedPreferences.getInstance();
    final done = p.getBool('onboarding_complete') ?? false;
    
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
    _scaleCtrl.dispose();
    _glowCtrl.dispose();
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
            AnimatedBuilder(
              animation: Listenable.merge([_scaleAnim, _glowAnim]),
              builder: (_, __) {
                return Transform.scale(
                  scale: _scaleAnim.value,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(
                        color: const Color(0xFF58A6FF).withOpacity(_glowAnim.value * 0.4),
                        blurRadius: 30,
                        spreadRadius: 5,
                      )],
                    ),
                    child: Image.asset('assets/images/mehd_logo.png', width: 110, height: 110),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            const Text('MEHD AI',
              style: TextStyle(
                color: Color(0xFF58A6FF),
                fontSize: 22,
                letterSpacing: 8,
                fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'Capital is a seed, not a sacrifice',
              style: TextStyle(
                color: Color(0xFF555555),
                fontSize: 11,
                letterSpacing: 2)),
            const SizedBox(height: 40),
            SizedBox(
              width: 24, height: 24,
              child: CircularProgressIndicator(
                  strokeWidth: 1.0,
                  color: const Color(0xFF58A6FF).withOpacity(0.3))),
            const SizedBox(height: 12),
            const Text('SYNCHRONIZING KERNEL...',
              style: TextStyle(
                color: Color(0xFF444444),
                fontSize: 8,
                letterSpacing: 2)),
          ],
        ),
      ),
    );
  }
}
