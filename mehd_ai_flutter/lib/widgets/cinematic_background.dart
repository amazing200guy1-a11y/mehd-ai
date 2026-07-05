import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mehd_ai_flutter/core/theme.dart';

/// REUSABLE COMPONENT: Cinematic Background
///
/// Provides the signature Mehd AI "Deep Void" aesthetic:
/// 1. Subtle grid lines (CustomPaint)
/// 2. Drifting particles (AnimatedBuilder)
/// 3. Deep radial gradient glow
///
/// This ensures consistent visual language across all institutional screens.
class CinematicBackground extends StatefulWidget {
  final Widget child;
  final bool showGrid;
  final bool showParticles;

  const CinematicBackground({
    super.key,
    required this.child,
    this.showGrid = true,
    this.showParticles = true,
  });

  @override
  State<CinematicBackground> createState() => _CinematicBackgroundState();
}

class _CinematicBackgroundState extends State<CinematicBackground>
    with SingleTickerProviderStateMixin {
  late List<_Particle> _particles;
  late AnimationController _particleCtrl;

  @override
  void initState() {
    super.initState();
    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();

    final rng = Random();
    _particles = List.generate(
        35,
        (_) => _Particle(
              x: rng.nextDouble(),
              y: rng.nextDouble(),
              size: rng.nextDouble() * 3.0 + 1.0,
              speed: rng.nextDouble() * 0.2 + 0.05,
              opacity: rng.nextDouble() * 0.4 + 0.1,
              angle: rng.nextDouble() * 2 * pi,
            ));
  }

  @override
  void dispose() {
    _particleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Solid base (Pure Black) - Ensures no transparency leaks
        Positioned.fill(child: Container(color: Colors.black)),

        // 2. Radial Pulse
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  const Color(0xFF001830).withOpacity(0.12),
                  const Color(0xFF000000),
                ],
              ),
            ),
          ),
        ),

        // 3. Grid Layer
        if (widget.showGrid)
          Positioned.fill(
            child: CustomPaint(
              painter: _GridPainter(),
            ),
          ),

        // 4. Particle Layer
        if (widget.showParticles)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _particleCtrl,
              builder: (context, _) => CustomPaint(
                painter: _ParticlePainter(
                  particles: _particles,
                  time: _particleCtrl.value,
                ),
              ),
            ),
          ),

        // 5. Content
        Positioned.fill(child: widget.child),
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = MehdAiTheme.blue.withOpacity(0.04)
      ..strokeWidth = 0.5;

    const spacing = 40.0;
    for (double i = 0; i <= size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i <= size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Particle {
  final double x, y, size, speed, opacity, angle;
  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.angle,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double time;

  _ParticlePainter({required this.particles, required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final drift = time * p.speed;
      final px = ((p.x + drift * cos(p.angle)) % 1.0) * size.width;
      final py = ((p.y + drift * sin(p.angle)) % 1.0) * size.height;

      final paint = Paint()
        ..color = MehdAiTheme.blue.withOpacity(p.opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, p.size);

      canvas.drawCircle(Offset(px, py), p.size, paint);

      final corePaint = Paint()
        ..color = Colors.white.withOpacity(p.opacity * 0.5);
      canvas.drawCircle(Offset(px, py), p.size * 0.4, corePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
