import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A premium, immersive loading widget that matches the Mehd AI identity.
/// Replaces generic CircularProgressIndicators.
class DenLoadingWidget extends StatefulWidget {
  final String message;

  const DenLoadingWidget({
    super.key,
    required this.message,
  });

  @override
  State<DenLoadingWidget> createState() => _DenLoadingWidgetState();
}

class _DenLoadingWidgetState extends State<DenLoadingWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1333),
    )..repeat(reverse: true);

    _opacityAnim = Tween<double>(begin: 0.05, end: 0.14).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _opacityAnim,
            builder: (context, child) {
              return Opacity(
                opacity: _opacityAnim.value,
                child: Image.asset(
                  'assets/images/mehd_logo.png',
                  width: 120,
                  height: 120,
                  fit: BoxFit.contain,
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            widget.message,
            style: GoogleFonts.jetBrainsMono(
              color: const Color(0xFF3B4048),
              fontSize: 11,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
