import 'package:flutter/material.dart';

class ZenChartTelemetry extends StatelessWidget {
  final Animation<double> scanlineAnim;
  final List<Color> agentColors;

  const ZenChartTelemetry({
    super.key,
    required this.scanlineAnim,
    required this.agentColors,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 11 Agent Heartbeat Dots
        Positioned(
          bottom: 40,
          left: 16,
          child: IgnorePointer(
            child: Row(
              children: [
                for (int i = 0; i < 11; i++)
                  _HeartbeatDot(
                    color: agentColors[i % agentColors.length],
                    animation: scanlineAnim,
                  ),
              ],
            ),
          ),
        ),
        // Scanline Overlay
        Positioned.fill(
          top: 60,
          bottom: 40,
          left: 16,
          right: 16,
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: scanlineAnim,
              builder: (_, __) => CustomPaint(
                painter: ScanlinePainter(progress: scanlineAnim.value),
              ),
            ),
          ),
        ),
        // Subtle Border Overlay
        Positioned.fill(
          top: 60,
          bottom: 40,
          left: 16,
          right: 16,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFF58A6FF).withOpacity(0.08),
                  width: 0.5,
                ),
              ),
            ),
          ),
        ),
        // SpaceX Telemetry Row (Top Left)
        const Positioned(
          top: 6,
          left: 6,
          child: IgnorePointer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TelemetryRow(label: 'SENT', value: 'ARMED', color: Color(0xFF00FF88)),
                _TelemetryRow(label: 'LAT', value: '12ms', color: Color(0xFF58A6FF)),
                _TelemetryRow(label: 'FEED', value: 'LIVE', color: Color(0xFF58A6FF)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeartbeatDot extends StatelessWidget {
  final Color color;
  final Animation<double> animation;

  const _HeartbeatDot({required this.color, required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        final double val = animation.value;
        final double pulse = val > 0.5 ? (1.0 - val) * 2 : val * 2;
        return Container(
          width: 4,
          height: 4,
          margin: const EdgeInsets.only(right: 3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.2 + 0.6 * pulse),
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.3), blurRadius: 4 * pulse)
            ],
          ),
        );
      },
    );
  }
}

class _TelemetryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _TelemetryRow({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label: ',
            style: const TextStyle(
                color: Color(0xFF1A1A1A),
                fontSize: 7,
                letterSpacing: 0.5,
                fontFamily: 'JetBrains Mono')),
        Text(value,
            style: TextStyle(
                color: color.withOpacity(0.4),
                fontSize: 7,
                letterSpacing: 0.5,
                fontFamily: 'JetBrains Mono')),
      ],
    );
  }
}

class ScanlinePainter extends CustomPainter {
  final double progress;
  ScanlinePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * progress;
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF58A6FF).withOpacity(0),
          const Color(0xFF58A6FF).withOpacity(0.015),
          const Color(0xFF58A6FF).withOpacity(0),
        ],
        stops: const [0, 0.5, 1],
      ).createShader(Rect.fromLTWH(0, y - 30, size.width, 60));

    canvas.drawRect(Rect.fromLTWH(0, y - 30, size.width, 60), paint);
  }

  @override
  bool shouldRepaint(ScanlinePainter oldDelegate) => oldDelegate.progress != progress;
}
