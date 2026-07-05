import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mehd_ai_flutter/core/theme.dart';
import 'dart:ui';

class RollingTicker extends StatefulWidget {
  final VoidCallback? onTickerTap;

  const RollingTicker({super.key, this.onTickerTap});

  @override
  State<RollingTicker> createState() => _RollingTickerState();
}

class _RollingTickerState extends State<RollingTicker> {
  String? _uid;
  List<Map<String, dynamic>> _tickerItems = [];
  int _currentIndex = 0;
  Timer? _rotationTimer;

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    _startRotation();
  }

  void _startRotation() {
    _rotationTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (_tickerItems.isNotEmpty && mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % _tickerItems.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _rotationTimer?.cancel();
    super.dispose();
  }

  // FIX: Called via post-frame callback — never directly inside build()
  void _onNewItems(List<Map<String, dynamic>> items) {
    setState(() {
      _tickerItems = items;
      // Reset index if it's out of bounds after data changes
      if (_currentIndex >= _tickerItems.length) {
        _currentIndex = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('user_profiles')
          .doc(_uid)
          .collection('ticker_feed')
          .orderBy('timestamp', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        // FIX: Update state via post-frame callback, not as a build() side effect
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          final incoming = snapshot.data!.docs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList();
          if (incoming.length != _tickerItems.length) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _onNewItems(incoming);
            });
          }
        }

        // Provide a default empty state instead of hiding
        String message = 'Initializing underground feed...';
        String direction = 'HOLD';
        
        if (_tickerItems.isNotEmpty) {
          final safeIndex = _currentIndex.clamp(0, _tickerItems.length - 1);
          final currentItem = _tickerItems[safeIndex];
          message = currentItem['message'] as String? ?? 'Monitoring global flow...';
          direction = currentItem['direction'] as String? ?? 'HOLD';
        }

        Color accentColor = MehdAiTheme.blue;
        if (direction == 'BUY') accentColor = MehdAiTheme.green;
        if (direction == 'SELL') accentColor = MehdAiTheme.red;

        return GestureDetector(
          onTap: widget.onTickerTap,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              // FIX: BackdropFilter needs a non-transparent ancestor to render correctly.
              color: const Color(0xFF0A0A0A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: accentColor.withOpacity(0.35), width: 1),
              boxShadow: [
                BoxShadow(color: accentColor.withOpacity(0.06), blurRadius: 12, spreadRadius: 1),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      // Live glowing indicator dot
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accentColor,
                          boxShadow: [BoxShadow(color: accentColor, blurRadius: 6)],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Message with animated crossfade on change
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 800),
                          transitionBuilder: (Widget child, Animation<double> animation) {
                            return FadeTransition(opacity: animation, child: child);
                          },
                          child: Text(
                            message,
                            key: ValueKey<String>(message),
                            style: MehdAiTheme.terminalStyle.copyWith(
                              color: MehdAiTheme.textPrimary,
                              height: 1.35,
                              fontSize: 13,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.chevron_right, color: MehdAiTheme.textSecondary, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
