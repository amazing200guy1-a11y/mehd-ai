import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mehd_ai_flutter/services/auth_service.dart';
import 'package:provider/provider.dart';

/// SECURITY: Inactivity Guard
///
/// Automatically logs the user out after [timeoutDuration] of inactivity.
/// "Inactivity" = no taps, swipes, or keyboard input anywhere in the app.
///
/// Why this matters for a financial app:
///   - If a user walks away from their phone at a coffee shop, anyone could
///     pick it up and execute trades.
///   - Institutional-grade apps (Bloomberg, Interactive Brokers) all auto-lock
///     after 5-15 minutes of inactivity.
///   - This is required by OWASP MASVS L2 for financial applications.
///
/// How it works:
///   1. Wraps the entire app in a GestureDetector that listens for ANY touch.
///   2. Every touch resets the inactivity timer.
///   3. When the timer expires, the user is logged out and sent to the auth screen.

class InactivityGuard extends StatefulWidget {
  final Widget child;
  final Duration timeoutDuration;

  const InactivityGuard({
    super.key,
    required this.child,
    this.timeoutDuration = const Duration(minutes: 15),
  });

  @override
  State<InactivityGuard> createState() => _InactivityGuardState();
}

class _InactivityGuardState extends State<InactivityGuard>
    with WidgetsBindingObserver {
  Timer? _inactivityTimer;
  late final FocusNode _keyboardFocusNode; // FIX #17: Avoid FocusNode leak

  @override
  void initState() {
    super.initState();
    _keyboardFocusNode = FocusNode();
    WidgetsBinding.instance.addObserver(this);
    _resetTimer();
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    _keyboardFocusNode.dispose(); // FIX #17: Properly dispose FocusNode
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Called when the app goes to background/foreground
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // App went to background — start a shorter timer (5 min)
      _inactivityTimer?.cancel();
      _inactivityTimer = Timer(const Duration(minutes: 5), _handleTimeout);
    } else if (state == AppLifecycleState.resumed) {
      // App came back — reset to full timer
      _resetTimer();
    }
  }

  void _resetTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(widget.timeoutDuration, _handleTimeout);
  }

  void _handleTimeout() {
    // Only logout if user is actually logged in
    final authService = context.read<AuthService>();
    if (authService.isLoggedIn) {
      debugPrint(
          'SECURITY: Auto-logout triggered after ${widget.timeoutDuration.inMinutes} minutes of inactivity');
      authService.signOut();

      // Navigate to root (AuthScreen will handle Login via /login route)
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Session expired for your security. Please sign in again.',
              style: TextStyle(color: Colors.black),
            ),
            backgroundColor: Color(0xFFD29922),
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Wrap child in detectors for ALL input types:
    // - GestureDetector catches touch/mouse (mobile + desktop)
    // - KeyboardListener catches keyboard input (desktop typing)
    // Without the keyboard listener, a desktop user typing a long Den
    // query could get auto-logged out mid-sentence after 15 minutes.
    return KeyboardListener(
      focusNode: _keyboardFocusNode, // FIX #17: Reuse instead of creating new
      onKeyEvent: (_) => _resetTimer(),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapDown: (_) => _resetTimer(),
        onPanDown: (_) => _resetTimer(),
        onScaleStart: (_) => _resetTimer(),
        child: widget.child,
      ),
    );
  }
}
