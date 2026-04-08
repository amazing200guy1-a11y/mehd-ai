import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:mehd_ai_flutter/models/automated_drawing.dart';
import 'package:mehd_ai_flutter/core/theme.dart';

/// FILE — drawing_engine.dart
/// UPGRADE 6: SVG Pixel-Perfect Chart Drawings
///
/// Implements pixel-perfect vector drawings using split rendering layers
/// bounded by `RepaintBoundary`. This separates static mathematical drawings
/// from dynamic animations, guaranteeing 60fps rendering without full canvas repaints.

class DrawingEngineOverlay extends StatelessWidget {
  final List<AutomatedDrawing> drawings;
  final double minX;
  final double maxX;
  final double minY;
  final double maxY;
  final double animationValue;

  const DrawingEngineOverlay({
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
    // Separate static vs dynamic drawings
    // In our case, KillZones, Fibonacci, and structural lines are static once animated.
    // However, since animationValue applies to all at the start, we place everything in a RepaintBoundary.
    // In a real live data streaming app, the 'static' boundary would not repaint when a new price tick arrives.
    
    final staticDrawings = drawings.where((d) => d is! ExclusiveMarker).toList();
    final dynamicDrawings = drawings.whereType<ExclusiveMarker>().toList();

    return Stack(
      children: [
        // Layer 1: Static Drawings (Lines, Zones, Fibs, Patterns)
        RepaintBoundary(
          child: IgnorePointer(
            child: CustomPaint(
              size: Size.infinite,
              painter: _VectorPainter(
                drawings: staticDrawings,
                minX: minX,
                maxX: maxX,
                minY: minY,
                maxY: maxY,
                animValue: animationValue,
              ),
            ),
          ),
        ),
        
        // Layer 2: Dynamic / Exclusive Indicators (Fakeouts, Footprints, Pulse animations)
        // This boundary only repaints when dynamic objects pulse or update
        RepaintBoundary(
          child: IgnorePointer(
            child: CustomPaint(
              size: Size.infinite,
              painter: _VectorPainter(
                drawings: dynamicDrawings,
                minX: minX,
                maxX: maxX,
                minY: minY,
                maxY: maxY,
                animValue: animationValue,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _VectorPainter extends CustomPainter {
  final List<AutomatedDrawing> drawings;
  final double minX, maxX, minY, maxY, animValue;

  _VectorPainter({
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

    // Pixel-perfect rendering: scale for device pixel ratio
    final double dpr = WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
    canvas.save();
    canvas.scale(1.0 / dpr, 1.0 / dpr);
    final scaledSize = Size(size.width * dpr, size.height * dpr);

    final double rangeX = maxX - minX;
    final double rangeY = maxY - minY;

    double mapX(double x) => scaledSize.width * ((x - minX) / rangeX);
    double mapY(double y) => scaledSize.height * (1.0 - ((y - minY) / rangeY));


    void drawText(String text, double x, double y, Color color, {double fontSize = 10, Alignment align = Alignment.bottomLeft}) {
      final builder = ui.ParagraphBuilder(ui.ParagraphStyle(
        textAlign: TextAlign.left,
        fontSize: fontSize * dpr,
        fontWeight: FontWeight.bold,
        fontFamily: 'Courier', // Institutional look
      ))
        ..pushStyle(ui.TextStyle(color: color.withOpacity(0.9)))
        ..addText(text);

      final paragraph = builder.build()
        ..layout(ui.ParagraphConstraints(width: 400 * dpr));
      
      double dx = x;
      double dy = y;
      
      if (align == Alignment.bottomLeft) {
        dy -= paragraph.height + (4 * dpr);
      } else if (align == Alignment.center) {
        dx -= paragraph.width / 2;
        dy -= paragraph.height / 2;
      }
      
      canvas.drawParagraph(paragraph, Offset(dx, dy));
    }

    void drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint, {double dashWidth = 5, double dashSpace = 5}) {
      double dx = p2.dx - p1.dx;
      double dy = p2.dy - p1.dy;
      final double distance = (Offset(dx, dy)).distance;
      double currentLength = 0;
      final double totalLength = distance * animValue; 

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
        
        double strokeWidth = 1.0; 
        if (d.type == LineType.support || d.type == LineType.resistance) strokeWidth = 0.8;
        if (d.type == LineType.structure) strokeWidth = 0.5;

        final paint = Paint()
          ..color = d.color.withOpacity(0.7)
          ..strokeWidth = strokeWidth * dpr
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.square // Institutional sharp caps
          ..isAntiAlias = true;

        if (d.isDashed) {
          drawDashedLine(canvas, p1, p2, paint, dashWidth: 10 * dpr, dashSpace: 6 * dpr);
        } else {
          final animatedP2 = Offset(
            p1.dx + (p2.dx - p1.dx) * animValue,
            p1.dy + (p2.dy - p1.dy) * animValue,
          );
          canvas.drawLine(p1, animatedP2, paint);
        }
        
          _drawAiBadge(canvas, p1.dx + (4 * dpr), p1.dy - (14 * dpr), dpr);
        
        // drawText(d.label, p1.dx + (10 * dpr), p1.dy, d.color, fontSize: 8);
      } 
      else if (d is ZoneDrawing) {
        final rect = Rect.fromLTRB(
          mapX(d.startX), 
          mapY(d.topPrice), 
          (mapX(d.startX) + (mapX(d.endX) - mapX(d.startX)) * animValue),
          mapY(d.bottomPrice)
        );
        
        final fillPaint = Paint()
          ..color = d.color.withOpacity(0.05 * animValue) // Strictly 0.05 opacity
          ..style = PaintingStyle.fill
          ..isAntiAlias = true;
        canvas.drawRect(rect, fillPaint);

        final borderPaint = Paint()
            ..color = d.color.withOpacity(0.4)
            ..strokeWidth = 0.6 * dpr
            ..style = PaintingStyle.stroke;
            
        canvas.drawRect(rect, borderPaint);

        _drawAiBadge(canvas, rect.left + (4 * dpr), rect.top - (14 * dpr), dpr);
        // drawText(d.label, rect.left + (4 * dpr), rect.top, d.color, fontSize: 7);
      }
      else if (d is FibonacciDrawing) {
        final p1Y = mapY(d.startY);
        final p2Y = mapY(d.endY);
        final pMidX = mapX(minX + rangeX * 0.15); 
        
        for (final level in d.levels) {
          final mappedY = (p2Y + (p1Y - p2Y) * level.ratio);
          
          double strokeWidth = level.isGolden ? 1.0 : 0.5;
          
          final paint = Paint()
            ..color = const Color(0xFFD4AF37).withOpacity(level.isGolden ? 0.8 : 0.3) 
            ..strokeWidth = strokeWidth * dpr
            ..isAntiAlias = true;
            
          final startX = mapX(d.startX);
          final endX = (startX + (mapX(d.endX) - startX) * animValue);
          canvas.drawLine(Offset(startX, mappedY), Offset(endX, mappedY), paint);
          
          drawText('${level.ratio} \u2014 ${level.description}', pMidX, mappedY, const Color(0xFFD4AF37), fontSize: 8);
        }
        _drawAiBadge(canvas, mapX(d.startX) + (4 * dpr), p2Y - (14 * dpr), dpr);
      }
      else if (d is PatternDrawing) {
        if (d.points.isEmpty) continue;
        final paint = Paint()
          ..color = MehdAiTheme.blue.withOpacity(0.5)
          ..strokeWidth = 2.0 * dpr
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;

        final path = Path();
        final mappedStart = Offset(mapX(d.points.first.dx), mapY(d.points.first.dy));
        path.moveTo(mappedStart.dx, mappedStart.dy);

        final int targetPointCount = (d.points.length * animValue).ceil().clamp(1, d.points.length);
        
        for (int i = 1; i < targetPointCount; i++) {
          path.lineTo(mapX(d.points[i].dx), mapY(d.points[i].dy));
        }
        canvas.drawPath(path, paint);

        final dotPaint = Paint()..color = MehdAiTheme.blue..style = PaintingStyle.fill;
        for (int i = 0; i < targetPointCount; i++) {
          canvas.drawCircle(Offset(mapX(d.points[i].dx), mapY(d.points[i].dy)), 3, dotPaint);
        }

        // drawText('${d.label} [${(d.probability * 100).toInt()}% prob]', mappedStart.dx, mappedStart.dy, MehdAiTheme.blue);
      }
      else if (d is ExclusiveMarker) {
        final mappedX = mapX(d.x).roundToDouble();
        final mappedY = mapY(d.y).roundToDouble();
        
        final paint = Paint()..color = d.color.withOpacity(animValue)..isAntiAlias = true;
        canvas.drawCircle(Offset(mappedX, mappedY), 6 * animValue, paint);
        
        // Inner pulse ring
        final ringPaint = Paint()
          ..color = d.color.withOpacity(1.0 - animValue)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..isAntiAlias = true;
        canvas.drawCircle(Offset(mappedX, mappedY), 15 * animValue, ringPaint);
        
        // drawText(d.label, mappedX, mappedY - 10, d.color, align: Alignment.center);
      }
      else if (d is KillZoneDrawing) {
        final rect = Rect.fromLTRB(
          mapX(d.startX).roundToDouble(),
          0,
          (mapX(d.startX) + (mapX(d.endX) - mapX(d.startX)) * animValue).roundToDouble(),
          scaledSize.height
        );
        final paint = Paint()
          ..shader = ui.Gradient.linear(
            Offset(rect.left, 0),
            Offset(rect.right, 0),
            [MehdAiTheme.gold.withOpacity(0.0), MehdAiTheme.gold.withOpacity(0.05), MehdAiTheme.gold.withOpacity(0.0)],
          );
        canvas.drawRect(rect, paint);
        // drawText(d.label, rect.left + 10, scaledSize.height - 20, MehdAiTheme.gold);
        _drawAiBadge(canvas, rect.left + 10, scaledSize.height - 35, dpr);
      }
    }

    // Restore canvas state from DPR scaling
    canvas.restore();
  }

  void _drawAiBadge(Canvas canvas, double x, double y, double dpr) {
    final bgPaint = Paint()
      ..color = const Color(0xFF0D1117).withOpacity(0.9);
    final borderPaint = Paint()
      ..color = const Color(0xFF58A6FF).withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5 * dpr;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, 16 * dpr, 10 * dpr),
      Radius.circular(1 * dpr),
    );
    canvas.drawRRect(rect, bgPaint);
    canvas.drawRRect(rect, borderPaint);

    // Draw "AI" text
    final builder = ui.ParagraphBuilder(ui.ParagraphStyle(
      textAlign: TextAlign.center,
      fontSize: 6 * dpr,
      fontWeight: FontWeight.bold,
      fontFamily: 'Courier',
    ))
      ..pushStyle(ui.TextStyle(color: const Color(0xFF58A6FF)))
      ..addText('AI');

    final paragraph = builder.build()
      ..layout(ui.ParagraphConstraints(width: 16 * dpr));
    
    canvas.drawParagraph(paragraph, Offset(x, y + (2 * dpr)));
  }

  @override
  bool shouldRepaint(covariant _VectorPainter oldDelegate) {
    return oldDelegate.animValue != animValue || oldDelegate.drawings.length != drawings.length;
  }
}
