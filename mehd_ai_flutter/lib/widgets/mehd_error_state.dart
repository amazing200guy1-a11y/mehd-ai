import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// FILE — mehd_error_state.dart
///
/// Build Debrief: VS Code style error state.
/// Tiger logo watermark 0.06 opacity.
/// Red error text "> Connection lost. Retrying..." with a blinking cursor.

class MehdErrorState extends StatefulWidget {
  final String message;
  const MehdErrorState({super.key, required this.message});

  @override
  State<MehdErrorState> createState() => _MehdErrorStateState();
}

class _MehdErrorStateState extends State<MehdErrorState> with SingleTickerProviderStateMixin {
  late AnimationController _cursorController;
  late Animation<double> _cursorFade;

  @override
  void initState() {
    super.initState();
    _cursorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);

    _cursorFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cursorController, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _cursorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Opacity(
            opacity: 0.06,
            child: Image.asset(
              'assets/images/mehd_logo.png',
              width: 120,
              height: 120,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  '> ${widget.message}',
                  style: GoogleFonts.jetBrainsMono(
                    color: const Color(0xFFF85149), // Red error color
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              AnimatedBuilder(
                animation: _cursorFade,
                builder: (context, child) {
                  final isVisible = _cursorFade.value > 0.5;
                  return Opacity(
                    opacity: isVisible ? 1.0 : 0.0,
                    child: Container(
                      width: 6,
                      height: 12,
                      color: const Color(0xFFF85149),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
