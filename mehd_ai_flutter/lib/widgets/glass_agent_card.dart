import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mehd_ai_flutter/core/den_identity.dart';
import 'package:mehd_ai_flutter/core/theme.dart';
import 'package:mehd_ai_flutter/models/consensus_result.dart';

/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
///  GLASSMORPHISM AGENT CARD
///  Premium frosted-glass card for each of the 11 agents.
///  Features:
///  • BackdropFilter frosted glass with luminous border
///  • Procedurally rendered 3D geometric symbol per agent
///  • Ambient pulse animation on the border glow
///  • Vote status indicator with direction color
///  • Tap to expand reasoning (optional)
/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class GlassAgentCard extends StatefulWidget {
  final AgentIdentity agent;
  final AIVote? vote;
  final bool compact;

  const GlassAgentCard({
    super.key,
    required this.agent,
    this.vote,
    this.compact = false,
  });

  @override
  State<GlassAgentCard> createState() => _GlassAgentCardState();
}

class _GlassAgentCardState extends State<GlassAgentCard>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    // Pulse: breathing glow on border + symbol
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final agent = widget.agent;
    final vote = widget.vote;
    final hasVoted = vote != null;
    final accentColor = agent.nodeColor;

    // Vote direction color
    Color voteColor = MehdAiTheme.textSecondary;
    String voteText = '—';
    if (hasVoted) {
      switch (vote.direction) {
        case 'BUY':
          voteColor = MehdAiTheme.green;
          voteText = 'BUY';
          break;
        case 'SELL':
          voteColor = MehdAiTheme.red;
          voteText = 'SELL';
          break;
        default:
          voteColor = MehdAiTheme.grey; // HOLD = grey (idle/neutral)
          voteText = 'HOLD';
      }
    }

    final symbolSize = widget.compact ? 28.0 : 40.0;

    return GestureDetector(
      onTap: hasVoted ? () => setState(() => _expanded = !_expanded) : null,
      child: AnimatedBuilder(
        animation: _pulseAnim,
        builder: (context, _) {
          final pulseVal = _pulseAnim.value;

          return Container(
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 6 : 10,
              vertical: widget.compact ? 8 : 10,
            ),
            decoration: BoxDecoration(
              // Sharp glass fill — no blur
              color: const Color(0xFF101820),
              borderRadius: BorderRadius.circular(12),
              // Luminous border that breathes
              border: Border.all(
                color: accentColor.withOpacity(
                  0.2 + (hasVoted ? pulseVal * 0.4 : 0),
                ),
                width: hasVoted ? 1.0 : 0.5,
              ),
              // Ambient glow
              boxShadow: [
                if (hasVoted)
                  BoxShadow(
                    color: accentColor.withOpacity(0.06 + pulseVal * 0.14),
                    blurRadius: 20,
                    spreadRadius: -2,
                  ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Animated Geometric Symbol ──
                Transform.scale(
                  scale: 1.0 + (pulseVal * 0.08),
                  child: Transform.rotate(
                    angle: (pulseVal - 0.5) * 0.4,
                    child: SizedBox(
                      width: symbolSize,
                      height: symbolSize,
                      child: CustomPaint(
                        painter: _AgentSymbolPainter(
                          agentId: agent.id,
                          color: accentColor,
                          pulse: pulseVal,
                          hasVoted: hasVoted,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: widget.compact ? 4 : 6),

                // ── Agent Name ──
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    agent.displayName,
                    style: GoogleFonts.jetBrainsMono(
                      color: hasVoted
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                      fontSize: widget.compact ? 9 : 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                  ),
                ),

                if (!widget.compact) ...[
                  const SizedBox(height: 2),
                  // ── Personality Subtitle ──
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      agent.personality,
                      style: GoogleFonts.outfit(
                        color: accentColor.withOpacity(0.6),
                        fontSize: 9,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                    ),
                  ),
                ],

                SizedBox(height: widget.compact ? 3 : 6),

                // ── Vote Status ──
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Pulsing status dot
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: hasVoted
                              ? voteColor
                              : Colors.grey.withOpacity(0.3),
                          boxShadow: hasVoted
                              ? [
                                  BoxShadow(
                                    color: voteColor.withOpacity(0.6),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : [],
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        hasVoted
                            ? '$voteText ${(vote.confidence * 100).toInt()}%'
                            : 'STANDBY',
                        style: GoogleFonts.jetBrainsMono(
                          color: hasVoted
                              ? voteColor
                              : Colors.grey.withOpacity(0.4),
                          fontSize: widget.compact ? 8 : 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Expanded Reasoning ──
                if (_expanded && hasVoted) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: accentColor.withOpacity(0.15),
                      ),
                    ),
                    child: Text(
                      vote.reasoning,
                      style: GoogleFonts.jetBrainsMono(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 8,
                        height: 1.4,
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  PROCEDURAL GEOMETRIC SYMBOLS
//  Each agent gets a unique symbol drawn via CustomPainter.
//  These are lightweight, resolution-independent, and animate
//  with the pulse value for that "alive intelligence" feel.
// ═══════════════════════════════════════════════════════════

class _AgentSymbolPainter extends CustomPainter {
  final String agentId;
  final Color color;
  final double pulse;
  final bool hasVoted;

  _AgentSymbolPainter({
    required this.agentId,
    required this.color,
    required this.pulse,
    required this.hasVoted,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;
    final alpha = hasVoted ? 1.0 : 0.5;

    switch (agentId.toLowerCase()) {
      case 'phantom':
        _drawPhantomRing(canvas, center, radius, alpha);
        break;
      case 'oracle':
        _drawOraclePrism(canvas, center, radius, alpha);
        break;
      case 'don':
        _drawDonCrown(canvas, center, radius, alpha);
        break;
      case 'caesar':
        _drawCaesarSigil(canvas, center, radius, alpha);
        break;
      case 'sage':
        _drawSageSphere(canvas, center, radius, alpha);
        break;
      case 'guardian':
        _drawGuardianShield(canvas, center, radius, alpha);
        break;
      case 'titan':
        _drawTitanCube(canvas, center, radius, alpha);
        break;
      case 'atlas':
        _drawAtlasWeb(canvas, center, radius, alpha);
        break;
      case 'forge':
        _drawForgeAnvil(canvas, center, radius, alpha);
        break;
      case 'the don':
        _drawSupremeStar(canvas, center, radius, alpha);
        break;
      case 'sentinel':
        _drawSentinelEye(canvas, center, radius, alpha);
        break;
      default:
        _drawDefaultSymbol(canvas, center, radius, alpha);
    }
  }

  // ── PHANTOM: Ghostly dissolving torus ring ──
  void _drawPhantomRing(Canvas canvas, Offset c, double r, double a) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Outer ring — dashed / dissolving effect
    for (int i = 0; i < 24; i++) {
      final angle = (i / 24) * 2 * pi + (pulse * 0.5);
      final opacity = (sin(angle * 3 + pulse * pi) * 0.5 + 0.5) * a;
      paint.color = color.withOpacity(opacity * 0.8);

      final p1 = Offset(
        c.dx + cos(angle) * r * 0.85,
        c.dy + sin(angle) * r * 0.85,
      );
      final p2 = Offset(
        c.dx + cos(angle) * r,
        c.dy + sin(angle) * r,
      );
      canvas.drawLine(p1, p2, paint);
    }

    // Inner ring — solid
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = color.withOpacity(0.3 * a + pulse * 0.2);
    canvas.drawCircle(c, r * 0.55, paint);

    // Center void dot
    paint
      ..style = PaintingStyle.fill
      ..color = color.withOpacity(0.15 * a + pulse * 0.1);
    canvas.drawCircle(c, r * 0.15, paint);

    // Center accent
    paint
      ..style = PaintingStyle.fill
      ..color = color.withOpacity(0.08 * a);
    canvas.drawCircle(c, r * 0.25, paint);
  }

  // ── ORACLE: Crystal prism eye ──
  void _drawOraclePrism(Canvas canvas, Offset c, double r, double a) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = color.withOpacity(0.8 * a);

    // Diamond/rhombus shape
    final path = Path()
      ..moveTo(c.dx, c.dy - r * 0.9)
      ..lineTo(c.dx + r * 0.6, c.dy)
      ..lineTo(c.dx, c.dy + r * 0.9)
      ..lineTo(c.dx - r * 0.6, c.dy)
      ..close();
    canvas.drawPath(path, paint);

    // Inner diamond
    paint.color = color.withOpacity(0.4 * a);
    final inner = Path()
      ..moveTo(c.dx, c.dy - r * 0.5)
      ..lineTo(c.dx + r * 0.35, c.dy)
      ..lineTo(c.dx, c.dy + r * 0.5)
      ..lineTo(c.dx - r * 0.35, c.dy)
      ..close();
    canvas.drawPath(inner, paint);

    // Central eye circle
    paint
      ..style = PaintingStyle.fill
      ..color = color.withOpacity(0.2 * a + pulse * 0.15);
    canvas.drawCircle(c, r * 0.15, paint);

    // Light refraction lines
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = color.withOpacity(0.25 * a);
    canvas.drawLine(
      Offset(c.dx - r * 0.6, c.dy),
      Offset(c.dx + r * 0.6, c.dy),
      paint,
    );
    canvas.drawLine(
      Offset(c.dx, c.dy - r * 0.9),
      Offset(c.dx, c.dy + r * 0.9),
      paint,
    );

    // Inner accent
    paint
      ..style = PaintingStyle.fill
      ..color = color.withOpacity(0.1 * a + pulse * 0.05);
    canvas.drawCircle(c, r * 0.2, paint);
  }

  // ── DON (Research): Crown circuit ──
  void _drawDonCrown(Canvas canvas, Offset c, double r, double a) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = color.withOpacity(0.8 * a);

    // Crown shape — 5 points
    final crown = Path();
    final baseY = c.dy + r * 0.3;
    final topY = c.dy - r * 0.6;
    final midY = c.dy - r * 0.1;

    crown.moveTo(c.dx - r * 0.8, baseY);
    crown.lineTo(c.dx - r * 0.6, topY);
    crown.lineTo(c.dx - r * 0.3, midY);
    crown.lineTo(c.dx, topY - r * 0.15);
    crown.lineTo(c.dx + r * 0.3, midY);
    crown.lineTo(c.dx + r * 0.6, topY);
    crown.lineTo(c.dx + r * 0.8, baseY);

    canvas.drawPath(crown, paint);

    // Base line
    canvas.drawLine(
      Offset(c.dx - r * 0.8, baseY),
      Offset(c.dx + r * 0.8, baseY),
      paint,
    );

    // Circuit nodes at crown tips
    paint
      ..style = PaintingStyle.fill
      ..color = color.withOpacity(0.5 * a + pulse * 0.3);
    canvas.drawCircle(Offset(c.dx - r * 0.6, topY), 2.5, paint);
    canvas.drawCircle(Offset(c.dx, topY - r * 0.15), 3, paint);
    canvas.drawCircle(Offset(c.dx + r * 0.6, topY), 2.5, paint);
  }

  // ── CAESAR: Imperial command sigil ──
  void _drawCaesarSigil(Canvas canvas, Offset c, double r, double a) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = color.withOpacity(0.8 * a);

    // Outer octagon
    final path = Path();
    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * 2 * pi - pi / 2;
      final x = c.dx + cos(angle) * r * 0.9;
      final y = c.dy + sin(angle) * r * 0.9;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);

    // Inner star cross — 4 lines through center
    paint.color = color.withOpacity(0.4 * a);
    for (int i = 0; i < 4; i++) {
      final angle = (i / 4) * pi;
      canvas.drawLine(
        Offset(c.dx + cos(angle) * r * 0.85, c.dy + sin(angle) * r * 0.85),
        Offset(c.dx - cos(angle) * r * 0.85, c.dy - sin(angle) * r * 0.85),
        paint,
      );
    }

    // Center command node
    paint
      ..style = PaintingStyle.fill
      ..color = color.withOpacity(0.3 * a + pulse * 0.2);
    canvas.drawCircle(c, r * 0.18, paint);

    // Command ring
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = color.withOpacity(0.5 * a + pulse * 0.2);
    canvas.drawCircle(c, r * 0.35, paint);
  }

  // ── SAGE: Nested wisdom sphere (icosahedron wireframe) ──
  void _drawSageSphere(Canvas canvas, Offset c, double r, double a) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = color.withOpacity(0.6 * a);

    // Three concentric circles with slight rotation offset
    for (int layer = 0; layer < 3; layer++) {
      final layerR = r * (0.4 + layer * 0.25);
      paint.color = color.withOpacity((0.3 + layer * 0.15) * a);

      // Rotated hexagons to simulate 3D sphere
      final rotation = layer * (pi / 6) + pulse * 0.3;
      final hex = Path();
      for (int i = 0; i < 6; i++) {
        final angle = (i / 6) * 2 * pi + rotation;
        final x = c.dx + cos(angle) * layerR;
        final y = c.dy + sin(angle) * layerR * 0.7; // Perspective squash
        if (i == 0) {
          hex.moveTo(x, y);
        } else {
          hex.lineTo(x, y);
        }
      }
      hex.close();
      canvas.drawPath(hex, paint);
    }

    // Center dot
    paint
      ..style = PaintingStyle.fill
      ..color = color.withOpacity(0.4 * a + pulse * 0.2);
    canvas.drawCircle(c, 3, paint);
  }

  // ── GUARDIAN: Hexagonal shield matrix ──
  void _drawGuardianShield(Canvas canvas, Offset c, double r, double a) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = color.withOpacity(0.6 * a);

    // Main hexagon
    _drawHexagon(canvas, c, r * 0.9, paint);

    // Inner hexagon
    paint.color = color.withOpacity(0.35 * a);
    _drawHexagon(canvas, c, r * 0.55, paint);

    // Connecting lines from inner to outer vertices
    paint
      ..strokeWidth = 1.0
      ..color = color.withOpacity(0.2 * a);
    for (int i = 0; i < 6; i++) {
      final angle = (i / 6) * 2 * pi - pi / 2;
      final inner =
          Offset(c.dx + cos(angle) * r * 0.55, c.dy + sin(angle) * r * 0.55);
      final outer =
          Offset(c.dx + cos(angle) * r * 0.9, c.dy + sin(angle) * r * 0.9);
      canvas.drawLine(inner, outer, paint);
    }

    // Energy nodes at vertices
    paint
      ..style = PaintingStyle.fill
      ..color = color.withOpacity(0.5 * a + pulse * 0.3);
    for (int i = 0; i < 6; i++) {
      final angle = (i / 6) * 2 * pi - pi / 2;
      canvas.drawCircle(
        Offset(c.dx + cos(angle) * r * 0.9, c.dy + sin(angle) * r * 0.9),
        2.5,
        paint,
      );
    }

    // Center shield dot
    paint.color = color.withOpacity(0.3 * a + pulse * 0.15);
    canvas.drawCircle(c, r * 0.12, paint);
  }

  void _drawHexagon(Canvas canvas, Offset c, double r, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i / 6) * 2 * pi - pi / 2;
      final x = c.dx + cos(angle) * r;
      final y = c.dy + sin(angle) * r;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  // ── TITAN: Rotating wireframe data cube ──
  void _drawTitanCube(Canvas canvas, Offset c, double r, double a) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = color.withOpacity(0.6 * a);

    final s = r * 0.65;
    final angle = pulse * 0.4;

    // 3D cube vertices projected to 2D with slight rotation
    final cosA = cos(angle);
    final sinA = sin(angle);

    // Front face
    final List<Offset> front = [
      Offset(c.dx - s + sinA * s * 0.3, c.dy - s),
      Offset(c.dx + s + sinA * s * 0.3, c.dy - s),
      Offset(c.dx + s + sinA * s * 0.3, c.dy + s),
      Offset(c.dx - s + sinA * s * 0.3, c.dy + s),
    ];

    // Back face (offset for depth)
    final d = s * 0.4;
    final List<Offset> back = [
      Offset(front[0].dx + d * cosA, front[0].dy - d * 0.3),
      Offset(front[1].dx + d * cosA, front[1].dy - d * 0.3),
      Offset(front[2].dx + d * cosA, front[2].dy - d * 0.3),
      Offset(front[3].dx + d * cosA, front[3].dy - d * 0.3),
    ];

    // Draw back face (dimmer)
    paint.color = color.withOpacity(0.25 * a);
    for (int i = 0; i < 4; i++) {
      canvas.drawLine(back[i], back[(i + 1) % 4], paint);
    }

    // Draw connecting lines
    paint.color = color.withOpacity(0.35 * a);
    for (int i = 0; i < 4; i++) {
      canvas.drawLine(front[i], back[i], paint);
    }

    // Draw front face (brighter)
    paint.color = color.withOpacity(0.6 * a + pulse * 0.1);
    for (int i = 0; i < 4; i++) {
      canvas.drawLine(front[i], front[(i + 1) % 4], paint);
    }

    // Corner nodes
    paint
      ..style = PaintingStyle.fill
      ..color = color.withOpacity(0.5 * a + pulse * 0.2);
    for (final p in front) {
      canvas.drawCircle(p, 1.8, paint);
    }
  }

  // ── ATLAS: Quantum web — interconnected sphere ──
  void _drawAtlasWeb(Canvas canvas, Offset c, double r, double a) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = color.withOpacity(0.3 * a);

    final rng = Random(42); // Fixed seed for consistency
    final nodes = <Offset>[];

    // Generate nodes in a circular pattern
    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * 2 * pi;
      final dist = r * (0.4 + rng.nextDouble() * 0.5);
      nodes.add(Offset(
        c.dx + cos(angle) * dist,
        c.dy + sin(angle) * dist,
      ));
    }

    // Draw connections between nearby nodes
    for (int i = 0; i < nodes.length; i++) {
      for (int j = i + 1; j < nodes.length; j++) {
        final dist = (nodes[i] - nodes[j]).distance;
        if (dist < r * 1.2) {
          final opacity = (1.0 - dist / (r * 1.2)) * 0.4 * a;
          paint.color = color.withOpacity(opacity);
          canvas.drawLine(nodes[i], nodes[j], paint);
        }
      }
    }

    // Draw nodes
    paint
      ..style = PaintingStyle.fill
      ..color = color.withOpacity(0.5 * a + pulse * 0.2);
    for (final node in nodes) {
      canvas.drawCircle(node, 2, paint);
    }
  }

  // ── FORGE: Code anvil with binary streams ──
  void _drawForgeAnvil(Canvas canvas, Offset c, double r, double a) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = color.withOpacity(0.6 * a);

    // Anvil shape — simplified geometric
    final anvil = Path();
    // Top surface
    anvil.moveTo(c.dx - r * 0.5, c.dy - r * 0.2);
    anvil.lineTo(c.dx + r * 0.7, c.dy - r * 0.2);
    // Right horn
    anvil.lineTo(c.dx + r * 0.9, c.dy - r * 0.4);
    anvil.lineTo(c.dx + r * 0.9, c.dy - r * 0.1);
    anvil.lineTo(c.dx + r * 0.5, c.dy + r * 0.1);
    // Base
    anvil.lineTo(c.dx + r * 0.4, c.dy + r * 0.6);
    anvil.lineTo(c.dx - r * 0.4, c.dy + r * 0.6);
    anvil.lineTo(c.dx - r * 0.5, c.dy + r * 0.1);
    anvil.close();

    canvas.drawPath(anvil, paint);

    // Binary streams — falling particles
    paint
      ..style = PaintingStyle.fill
      ..color = color.withOpacity(0.35 * a);
    for (int i = 0; i < 5; i++) {
      final x = c.dx - r * 0.3 + i * r * 0.2;
      final yOff = (pulse * r * 2 + i * r * 0.5) % (r * 2) - r;
      final opacity = (1.0 - (yOff.abs() / r)) * 0.4 * a;
      if (opacity > 0) {
        paint.color = color.withOpacity(opacity);
        canvas.drawCircle(Offset(x, c.dy - r * 0.5 + yOff), 1.2, paint);
      }
    }
  }

  // ── THE DON (Supreme): Radiating polyhedron star ──
  void _drawSupremeStar(Canvas canvas, Offset c, double r, double a) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // 8-pointed star
    final star = Path();
    for (int i = 0; i < 16; i++) {
      final angle = (i / 16) * 2 * pi - pi / 2;
      final dist = i.isEven ? r * 0.9 : r * 0.4;
      final x = c.dx + cos(angle) * dist;
      final y = c.dy + sin(angle) * dist;
      if (i == 0) {
        star.moveTo(x, y);
      } else {
        star.lineTo(x, y);
      }
    }
    star.close();

    paint.color = color.withOpacity(0.7 * a + pulse * 0.15);
    canvas.drawPath(star, paint);

    // Inner ring
    paint
      ..strokeWidth = 2.0
      ..color = color.withOpacity(0.5 * a + pulse * 0.2);
    canvas.drawCircle(c, r * 0.3, paint);

    // Center blazing dot
    paint
      ..style = PaintingStyle.fill
      ..color = color.withOpacity(0.6 * a + pulse * 0.3);
    canvas.drawCircle(c, r * 0.1, paint);
  }

  // ── SENTINEL: Scanning paradox eye ──
  void _drawSentinelEye(Canvas canvas, Offset c, double r, double a) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = color.withOpacity(0.6 * a);

    // Eye outline — two curved arcs
    final eye = Path();
    eye.moveTo(c.dx - r * 0.95, c.dy);
    eye.quadraticBezierTo(c.dx, c.dy - r * 0.8, c.dx + r * 0.95, c.dy);
    canvas.drawPath(eye, paint);

    final eyeBottom = Path();
    eyeBottom.moveTo(c.dx - r * 0.95, c.dy);
    eyeBottom.quadraticBezierTo(c.dx, c.dy + r * 0.8, c.dx + r * 0.95, c.dy);
    canvas.drawPath(eyeBottom, paint);

    // Iris circle
    paint
      ..strokeWidth = 1.5
      ..color = color.withOpacity(0.5 * a + pulse * 0.2);
    canvas.drawCircle(c, r * 0.35, paint);

    // Pupil
    paint
      ..style = PaintingStyle.fill
      ..color = color.withOpacity(0.4 * a + pulse * 0.25);
    canvas.drawCircle(c, r * 0.15, paint);

    // Scanning beam — horizontal line pulsing
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = color.withOpacity(0.3 * a * pulse);
    final scanY = c.dy + (pulse - 0.5) * r * 0.6;
    canvas.drawLine(
      Offset(c.dx - r * 0.8, scanY),
      Offset(c.dx + r * 0.8, scanY),
      paint,
    );
  }

  // ── Default fallback ──
  void _drawDefaultSymbol(Canvas canvas, Offset c, double r, double a) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = color.withOpacity(0.5 * a);
    canvas.drawCircle(c, r * 0.7, paint);
    paint
      ..style = PaintingStyle.fill
      ..color = color.withOpacity(0.2 * a);
    canvas.drawCircle(c, r * 0.2, paint);
  }

  @override
  bool shouldRepaint(_AgentSymbolPainter oldDelegate) =>
      oldDelegate.pulse != pulse ||
      oldDelegate.hasVoted != hasVoted ||
      oldDelegate.agentId != agentId;
}

// ═══════════════════════════════════════════════════════════
//  AGENT GRID — Displays all 11 agents in glassmorphism
//  cards grouped by layer. Used in the VOTES tab.
// ═══════════════════════════════════════════════════════════

class AgentGlassGrid extends StatelessWidget {
  final ConsensusResult? consensus;

  const AgentGlassGrid({super.key, this.consensus});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLayerSection(
            'THE RESEARCH',
            'Intelligence Layer',
            const Color(0xFF6A0DAD),
            ['don', 'phantom', 'oracle'],
          ),
          const SizedBox(height: 16),
          _buildLayerSection(
            'THE STRATEGY',
            'Strategy Layer',
            MehdAiTheme.gold,
            ['caesar', 'sage', 'guardian'],
          ),
          const SizedBox(height: 16),
          _buildLayerSection(
            'OLYMPUS',
            'Quantitative Layer',
            MehdAiTheme.blue,
            ['titan', 'atlas', 'forge'],
          ),
          const SizedBox(height: 16),
          _buildLayerSection(
            'SUPREME & GUARDIAN',
            'Override Layer',
            Colors.white,
            ['the don', 'sentinel'],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildLayerSection(
    String layerName,
    String subtitle,
    Color accent,
    List<String> agentIds,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Layer header
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent,
                  boxShadow: [
                    BoxShadow(
                      color: accent.withOpacity(0.5),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                layerName,
                style: GoogleFonts.jetBrainsMono(
                  color: accent,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                subtitle,
                style: GoogleFonts.outfit(
                  color: accent.withOpacity(0.4),
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
        // Agent cards row
        Row(
          children: agentIds.map((id) {
            final agent = DenIdentity.getIdentity(id);
            final vote = _findVoteForAgent(id);
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: GlassAgentCard(
                  agent: agent,
                  vote: vote,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  AIVote? _findVoteForAgent(String agentId) {
    if (consensus == null) return null;

    // Map agent IDs to backend model names
    const agentToModel = {
      'don': 'grok',
      'phantom': 'perplexity',
      'oracle': 'gemini',
      'caesar': 'gpt-4',
      'sage': 'claude',
      'guardian': 'llama',
      'titan': 'deepseek',
      'atlas': 'openai-o3',
      'forge': 'codestral',
      'the don': 'chairman',
      'sentinel': 'sentinel',
    };

    final modelName = agentToModel[agentId.toLowerCase()];
    if (modelName == null) return null;

    try {
      return consensus!.votes.firstWhere(
        (v) => v.modelName.toLowerCase() == modelName,
      );
    } catch (_) {
      return null;
    }
  }
}
