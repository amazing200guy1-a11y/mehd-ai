import 'package:flutter/material.dart';
import 'package:mehd_ai_flutter/core/theme.dart';
import 'package:mehd_ai_flutter/models/consensus_result.dart';
import 'dart:math' as math;
import 'dart:async';

class WarRoomScreen extends StatefulWidget {
  final ConsensusResult? consensus;
  final bool isAnalyzing;
  
  const WarRoomScreen({super.key, this.consensus, required this.isAnalyzing});

  @override
  State<WarRoomScreen> createState() => _WarRoomScreenState();
}

class _WarRoomScreenState extends State<WarRoomScreen> with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _radarCtrl;
  
  String _liveText = "";
  Timer? _typewriterTimer;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _radarCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    _startTypewriter();
  }

  @override
  void didUpdateWidget(WarRoomScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnalyzing != oldWidget.isAnalyzing) {
      if (widget.isAnalyzing) {
         setState(() => _liveText = "");
         _startTypewriter();
      }
    }
  }

  void _startTypewriter() {
    _typewriterTimer?.cancel();
    const fullText = "DECRYPTING MARKET VECTORS...\n\n"
        "SENTIMENT LAYER: Scanning global news.\nSTRATEGY LAYER: Analyzing liquidity sweeps.\nMATH LAYER: Running Monte Carlo probability.\n\n"
        "Awaiting final consensus...";
    
    int charIndex = 0;
    _typewriterTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (charIndex < fullText.length) {
        if (mounted) setState(() => _liveText = fullText.substring(0, charIndex + 1));
        charIndex++;
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _radarCtrl.dispose();
    _typewriterTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark cinematic
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shield, color: MehdAiTheme.red),
            const SizedBox(width: 12),
            Text('INSTITUTIONAL WAR ROOM', style: MehdAiTheme.headingStyle.copyWith(color: MehdAiTheme.red, letterSpacing: 4)),
          ],
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: MehdAiTheme.red),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: MehdAiTheme.red.withOpacity(0.3), height: 1),
        ),
      ),
      body: Row(
        children: [
          // LEFT: Neural Map
          Expanded(flex: 3, child: _buildNeuralMap()),
          VerticalDivider(width: 1, color: MehdAiTheme.red.withOpacity(0.2)),
          
          // CENTER: 3D Radar/Cylinder
          Expanded(flex: 4, child: _buildRadar()),
          VerticalDivider(width: 1, color: MehdAiTheme.red.withOpacity(0.2)),
          
          // RIGHT: Live Decrypt Stream
          Expanded(flex: 3, child: _buildLiveDecrypt()),
        ],
      ),
    );
  }

  Widget _buildNeuralMap() {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [MehdAiTheme.red.withOpacity(0.1), Colors.black],
          radius: 0.8,
        )
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(double.infinity, double.infinity),
            painter: NeuralConnectionPainter(pulse: _pulseCtrl),
          ),
          _buildNode(0, -100, "Math 1"),
          _buildNode(-80, -40, "Math 2"),
          _buildNode(80, -40, "Math 3"),
          _buildNode(-120, 60, "Strat 1"),
          _buildNode(0, 40, "Strat 2"),
          _buildNode(120, 60, "Strat 3"),
          _buildNode(-80, 160, "Sent 1"),
          _buildNode(0, 140, "Sent 2"),
          _buildNode(80, 160, "Sent 3"),
          // Sentinel Center
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) => Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black,
                border: Border.all(color: MehdAiTheme.red, width: 2),
                boxShadow: [BoxShadow(color: MehdAiTheme.red.withOpacity(_pulseCtrl.value), blurRadius: 30)],
              ),
              child: const Icon(Icons.remove_red_eye, color: MehdAiTheme.red, size: 30),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildNode(double dx, double dy, String label) {
    return Transform.translate(
      offset: Offset(dx, dy),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12, height: 12,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: MehdAiTheme.red),
          ),
          const SizedBox(height: 4),
          Text(label, style: MehdAiTheme.labelStyle.copyWith(color: MehdAiTheme.red, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildRadar() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _radarCtrl,
          builder: (_, __) {
            return CustomPaint(
              size: const Size(300, 300),
              painter: RadarPainter(angle: _radarCtrl.value * 2 * math.pi, consensus: widget.consensus),
            );
          },
        ),
        const SizedBox(height: 40),
        if (widget.consensus != null)
           Text('CONSENSUS: ${widget.consensus!.consensusPercentage}%', style: MehdAiTheme.headingStyle.copyWith(fontSize: 24, color: MehdAiTheme.red))
        else
           Text('AWAITING DATA', style: MehdAiTheme.headingStyle.copyWith(color: MehdAiTheme.textSecondary)),
      ],
    );
  }

  Widget _buildLiveDecrypt() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('LIVE DECRYPT STREAM', style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.red, fontWeight: FontWeight.bold)),
          const Divider(color: MehdAiTheme.red),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                _liveText,
                style: MehdAiTheme.terminalStyle.copyWith(height: 1.5, color: MehdAiTheme.textPrimary),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class NeuralConnectionPainter extends CustomPainter {
  final Animation<double> pulse;

  NeuralConnectionPainter({required this.pulse}) : super(repaint: pulse);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = MehdAiTheme.red.withOpacity(0.2 + (pulse.value * 0.3))
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final nodes = [
      Offset(center.dx, center.dy - 100),
      Offset(center.dx - 80, center.dy - 40),
      Offset(center.dx + 80, center.dy - 40),
      Offset(center.dx - 120, center.dy + 60),
      Offset(center.dx, center.dy + 40),
      Offset(center.dx + 120, center.dy + 60),
      Offset(center.dx - 80, center.dy + 160),
      Offset(center.dx, center.dy + 140),
      Offset(center.dx + 80, center.dy + 160),
    ];

    for (var node in nodes) {
      canvas.drawLine(center, node, paint);
    }
  }

  @override
  bool shouldRepaint(NeuralConnectionPainter oldDelegate) => true;
}

class RadarPainter extends CustomPainter {
  final double angle;
  final ConsensusResult? consensus;

  RadarPainter({required this.angle, this.consensus});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background rings
    final ringPaint = Paint()
      ..color = MehdAiTheme.red.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    canvas.drawCircle(center, radius, ringPaint);
    canvas.drawCircle(center, radius * 0.66, ringPaint);
    canvas.drawCircle(center, radius * 0.33, ringPaint);

    // Crosshairs
    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, size.height), ringPaint);
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), ringPaint);

    // Radar Sweep
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: 0.0,
        endAngle: math.pi / 2,
        colors: [MehdAiTheme.red.withOpacity(0), MehdAiTheme.red.withOpacity(0.5)],
        transform: GradientRotation(angle - (math.pi / 2)),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, radius, sweepPaint);

    // Render nodes based on consensus
    if (consensus != null) {
      final nodePaint = Paint()..color = MehdAiTheme.red..style = PaintingStyle.fill;
      final int activeNodes = consensus!.votes.length;
      for (int i = 0; i < 9; i++) {
        final nodeAngle = (i * (math.pi * 2) / 9) - (math.pi / 2);
        final dist = i < activeNodes ? radius * 0.8 : radius * 0.4;
        final alpha = i < activeNodes ? 1.0 : 0.2;
        
        canvas.drawCircle(
          Offset(center.dx + math.cos(nodeAngle) * dist, center.dy + math.sin(nodeAngle) * dist),
          6.0,
          nodePaint..color = MehdAiTheme.red.withOpacity(alpha),
        );
      }
    }
  }

  @override
  bool shouldRepaint(RadarPainter oldDelegate) => true;
}
