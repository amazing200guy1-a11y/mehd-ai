import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:mehd_ai_flutter/models/automated_drawing.dart';
import 'package:mehd_ai_flutter/core/theme.dart';

/// A massive, strict `CustomPainter` that intercepts AI drawing mathematical geometries
/// and paints them physically onto the canvas grid in real time. Runs synchronously 
/// at 60fps utilizing standard pixel rasterization over `fl_chart`.

class ChartDrawingsOverlay extends StatelessWidget {
  final List<AutomatedDrawing> drawings;
  final double minX;
  final double maxX;
  final double minY;
  final double maxY;
  final double animationValue;

  const ChartDrawingsOverlay({
    super.key,
    required this.drawings,
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
    required this.animationValue,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _DrawingsPainter(
          drawings: drawings,
          minX: minX,
          maxX: maxX,
          minY: minY,
          maxY: maxY,
          animValue: animationValue,
        ),
      ),
    );
  }
}

class _DrawingsPainter extends CustomPainter {
  final List<AutomatedDrawing> drawings;
  final double minX, maxX, minY, maxY, animValue;

  _DrawingsPainter({
    required this.drawings,
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
    required this.animValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (drawings.isEmpty) return;

    final double rangeX = maxX - minX;
    final double rangeY = maxY - minY;

    // Helper to map logic data (like 1.0845) to pixel Y on canvas
    double mapX(double x) => size.width * ((x - minX) / rangeX);
    double mapY(double y) => size.height * (1.0 - ((y - minY) / rangeY));

    // Paint reusable tools
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    void drawText(String text, double x, double y, Color color, {double fontSize = 10, Alignment align = Alignment.bottomLeft}) {
      textPainter.text = TextSpan(
        text: text,
        style: MehdAiTheme.terminalStyle.copyWith(color: color, fontSize: fontSize, fontWeight: FontWeight.bold),
      );
      textPainter.layout();
      
      double dx = x;
      double dy = y;
      
      if (align == Alignment.bottomLeft) {
        dy -= textPainter.height + 4;
      } else if (align == Alignment.center) {
        dx -= textPainter.width / 2;
        dy -= textPainter.height / 2;
      }
      
      textPainter.paint(canvas, Offset(dx, dy));
    }

    void drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint, {double dashWidth = 5, double dashSpace = 5}) {
      double dx = p2.dx - p1.dx;
      double dy = p2.dy - p1.dy;
      final double distance = (Offset(dx, dy)).distance;
      double currentLength = 0;
      final double totalLength = distance * animValue; // Animate line sweeping across

      canvas.save();
      canvas.translate(p1.dx, p1.dy);
      canvas.rotate((Offset(dx, dy)).direction);

      while (currentLength < totalLength) {
        final double drawLength = (currentLength + dashWidth) < totalLength ? dashWidth : totalLength - currentLength;
        canvas.drawLine(Offset(currentLength, 0), Offset(currentLength + drawLength, 0), paint);
        currentLength += dashWidth + dashSpace;
      }
      canvas.restore();
    }

    for (final d in drawings) {
      if (d is LineDrawing) {
        final p1 = Offset(mapX(d.startX), mapY(d.startY));
        final p2 = Offset(mapX(d.endX), mapY(d.endY));
        final paint = Paint()
          ..color = d.color.withOpacity(0.8)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;

        if (d.isDashed) {
          drawDashedLine(canvas, p1, p2, paint, dashWidth: 4, dashSpace: 4);
        } else {
          // Animate solid line
          final animatedP2 = Offset(
            p1.dx + (p2.dx - p1.dx) * animValue,
            p1.dy + (p2.dy - p1.dy) * animValue,
          );
          canvas.drawLine(p1, animatedP2, paint);
        }
        
        // Draw Label slightly above line
        // drawText(d.label, p1.dx + 10, p1.dy, d.color);
      } 
      else if (d is ZoneDrawing) {
        final rect = Rect.fromLTRB(
          mapX(d.startX), 
          mapY(d.topPrice), 
          mapX(d.startX) + (mapX(d.endX) - mapX(d.startX)) * animValue, // Animate width 
          mapY(d.bottomPrice)
        );
        
        final fillPaint = Paint()
          ..color = d.color.withOpacity(d.opacity * animValue)
          ..style = PaintingStyle.fill;
        canvas.drawRect(rect, fillPaint);

        if (d.isDashed) { // For FVG or Liquidity borders
          final borderPaint = Paint()
            ..color = d.color.withOpacity(0.6)
            ..strokeWidth = 1
            ..style = PaintingStyle.stroke;
          drawDashedLine(canvas, rect.topLeft, rect.topRight, borderPaint);
          drawDashedLine(canvas, rect.bottomLeft, rect.bottomRight, borderPaint);
        }

        // drawText(d.label, rect.left + 4, rect.top, d.color);
      }
      else if (d is FibonacciDrawing) {
        final p1Y = mapY(d.startY);
        final p2Y = mapY(d.endY);
        final pMidX = mapX(minX + rangeX * 0.15); // Anchor labels
        
        for (final level in d.levels) {
          final mappedY = p2Y + (p1Y - p2Y) * level.ratio;
          final paint = Paint()
            ..color = const Color(0xFFD4AF37).withOpacity(level.isGolden ? 0.9 : 0.4) // Gold
            ..strokeWidth = level.isGolden ? 2 : 1;
            
          final startX = mapX(d.startX);
          final endX = startX + (mapX(d.endX) - startX) * animValue;
          canvas.drawLine(Offset(startX, mappedY), Offset(endX, mappedY), paint);
          
          drawText('${level.ratio} — ${level.description}', pMidX, mappedY, const Color(0xFFD4AF37));
        }
      }
      else if (d is PatternDrawing) {
        if (d.points.isEmpty) continue;
        final paint = Paint()
          ..color = MehdAiTheme.blue.withOpacity(0.5)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;

        final path = Path();
        final mappedStart = Offset(mapX(d.points.first.dx), mapY(d.points.first.dy));
        path.moveTo(mappedStart.dx, mappedStart.dy);

        // Animate path drawing
        final int targetPointCount = (d.points.length * animValue).ceil().clamp(1, d.points.length);
        
        for (int i = 1; i < targetPointCount; i++) {
          path.lineTo(mapX(d.points[i].dx), mapY(d.points[i].dy));
        }
        canvas.drawPath(path, paint);

        // Draw circles at vertices
        final dotPaint = Paint()..color = MehdAiTheme.blue..style = PaintingStyle.fill;
        for (int i = 0; i < targetPointCount; i++) {
          canvas.drawCircle(Offset(mapX(d.points[i].dx), mapY(d.points[i].dy)), 3, dotPaint);
        }

        // drawText('${d.label} [${(d.probability * 100).toInt()}% prob]', mappedStart.dx, mappedStart.dy, MehdAiTheme.blue);
      }
      else if (d is ExclusiveMarker) {
        final mappedX = mapX(d.x);
        final mappedY = mapY(d.y);
        
        final paint = Paint()..color = d.color.withOpacity(animValue);
        canvas.drawCircle(Offset(mappedX, mappedY), 6 * animValue, paint);
        
        // Inner pulse ring
        final ringPaint = Paint()
          ..color = d.color.withOpacity(1.0 - animValue)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawCircle(Offset(mappedX, mappedY), 15 * animValue, ringPaint);
        
        // drawText(d.label, mappedX, mappedY - 10, d.color, align: Alignment.center);
      }
      else if (d is KillZoneDrawing) {
        final rect = Rect.fromLTRB(
          mapX(d.startX),
          0,
          mapX(d.startX) + (mapX(d.endX) - mapX(d.startX)) * animValue,
          size.height
        );
        // Subtle vertical shading matrix
        final paint = Paint()
          ..shader = ui.Gradient.linear(
            Offset(rect.left, 0),
            Offset(rect.right, 0),
            [MehdAiTheme.gold.withOpacity(0.0), MehdAiTheme.gold.withOpacity(0.05), MehdAiTheme.gold.withOpacity(0.0)],
          );
        canvas.drawRect(rect, paint);
        // drawText(d.label, rect.left + 10, size.height - 20, MehdAiTheme.gold);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DrawingsPainter oldDelegate) {
    return oldDelegate.animValue != animValue || oldDelegate.drawings.length != drawings.length;
  }
}
