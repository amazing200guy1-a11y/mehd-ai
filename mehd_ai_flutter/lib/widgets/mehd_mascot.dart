import 'package:flutter/material.dart';

/// Temporary placeholder widget for the Mehd AI cyber tiger mascot while
/// we transition to the brand new 200+ frame custom animations.
class MehdMascot extends StatefulWidget {
  final bool isWorking;
  final double size;

  const MehdMascot({
    super.key,
    this.isWorking = false,
    this.size = 120,
  });

  @override
  State<MehdMascot> createState() => _MehdMascotState();
}

class _MehdMascotState extends State<MehdMascot>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF0D1117),
            border: Border.all(
              color: Colors.tealAccent.withOpacity(_pulseAnimation.value),
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.tealAccent.withOpacity(0.3 * _pulseAnimation.value),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.bolt,
                color: Colors.tealAccent.withOpacity(_pulseAnimation.value),
                size: widget.size * 0.35,
              ),
              const SizedBox(height: 4),
              Text(
                widget.isWorking ? 'WORKING' : 'READY',
                style: TextStyle(
                  color: Colors.tealAccent.withOpacity(_pulseAnimation.value),
                  fontSize: widget.size * 0.09,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

