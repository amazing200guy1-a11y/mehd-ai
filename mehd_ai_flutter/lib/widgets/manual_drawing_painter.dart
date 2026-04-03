import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:mehd_ai_flutter/core/theme.dart';
import 'package:mehd_ai_flutter/models/manual_drawing.dart';

/// FILE — manual_drawing_painter.dart
/// Renders user-created manual drawings with the same pixel-perfect quality
/// as the AI drawing engine. Manual drawings carry an "M" badge.

class ManualDrawingPainter extends CustomPainter {
  final List<ManualDrawing> drawings;
  final double minX, maxX, minY, maxY;

  ManualDrawingPainter({
    required this.drawings,
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (drawings.isEmpty) return;

    final double dpr = WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
    canvas.save();
    canvas.scale(1.0 / dpr, 1.0 / dpr);
    final s = Size(size.width * dpr, size.height * dpr);

    final rangeX = maxX - minX;
    final rangeY = maxY - minY;
    double mapX(double x) => s.width * ((x - minX) / rangeX);
    double mapY(double y) => s.height * (1.0 - ((y - minY) / rangeY));

    for (final d in drawings) {
      final isSelected = d.isSelected;
      final selectionGlow = isSelected ? MehdAiTheme.blue.withOpacity(0.6) : null;

      if (d is ManualTrendline) {
        _drawTrendline(canvas, d, mapX, mapY, dpr, s, selectionGlow);
      } else if (d is ManualHorizontalLine) {
        _drawHLine(canvas, d, mapX, mapY, dpr, s, selectionGlow);
      } else if (d is ManualZone) {
        _drawZone(canvas, d, mapX, mapY, dpr, s, selectionGlow);
      } else if (d is ManualFibonacci) {
        _drawFib(canvas, d, mapX, mapY, dpr, s, selectionGlow);
      }
    }

    canvas.restore();
  }

  void _drawTrendline(Canvas canvas, ManualTrendline d,
      double Function(double) mapX, double Function(double) mapY,
      double dpr, Size s, Color? glow) {
    final p1 = Offset(mapX(d.startX), mapY(d.startY));
    final p2 = Offset(mapX(d.endX), mapY(d.endY));

    final paint = Paint()
      ..color = glow ?? MehdAiTheme.blue.withOpacity(0.8)
      ..strokeWidth = 1.0 * dpr
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square // Sharp caps
      ..isAntiAlias = true;
    canvas.drawLine(p1, p2, paint);

    // Institutional Endpoint handles (Square, not circle)
    final handlePaint = Paint()
      ..color = MehdAiTheme.blue
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromCenter(center: p1, width: 4.0 * dpr, height: 4.0 * dpr), handlePaint);
    canvas.drawRect(Rect.fromCenter(center: p2, width: 4.0 * dpr, height: 4.0 * dpr), handlePaint);

    _drawBadge(canvas, p1.dx + 14 * dpr, p1.dy - 14 * dpr, dpr);
  }

  void _drawHLine(Canvas canvas, ManualHorizontalLine d,
      double Function(double) mapX, double Function(double) mapY,
      double dpr, Size s, Color? glow) {
    final y = mapY(d.priceLevel);

    final paint = Paint()
      ..color = glow ?? MehdAiTheme.gold.withOpacity(0.7)
      ..strokeWidth = 0.8 * dpr
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    // Sharp dashed line
    double x = 0;
    while (x < s.width) {
      final end = (x + 10.0 * dpr).clamp(0, s.width).toDouble();
      canvas.drawLine(Offset(x, y), Offset(end, y), paint);
      x += 16.0 * dpr;
    }

    _drawPriceLabel(canvas, d.priceLevel, s.width - 85 * dpr, y, dpr);
    _drawBadge(canvas, 8.0 * dpr, y - 14.0 * dpr, dpr);
  }

  void _drawZone(Canvas canvas, ManualZone d,
      double Function(double) mapX, double Function(double) mapY,
      double dpr, Size s, Color? glow) {
    final topY = mapY(d.topPrice);
    final botY = mapY(d.bottomPrice);

    final fillPaint = Paint()
      ..color = (glow ?? MehdAiTheme.purple).withOpacity(0.05)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTRB(0, topY, s.width, botY), fillPaint);

    final borderPaint = Paint()
      ..color = (glow ?? MehdAiTheme.purple).withOpacity(0.4)
      ..strokeWidth = 0.6 * dpr
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, topY), Offset(s.width, topY), borderPaint);
    canvas.drawLine(Offset(0, botY), Offset(s.width, botY), borderPaint);

    _drawBadge(canvas, 8.0 * dpr, topY + 4.0 * dpr, dpr);
  }

  void _drawFib(Canvas canvas, ManualFibonacci d,
      double Function(double) mapX, double Function(double) mapY,
      double dpr, Size s, Color? glow) {
    final range = d.highPrice - d.lowPrice;

    for (final level in ManualFibonacci.levels) {
      final price = d.lowPrice + range * level;
      final y = mapY(price);
      final isGolden = level == 0.618;

      final paint = Paint()
        ..color = (glow ?? const Color(0xFFD4AF37)).withOpacity(isGolden ? 0.8 : 0.3)
        ..strokeWidth = (isGolden ? 1.0 : 0.5) * dpr
        ..isAntiAlias = true;

      canvas.drawLine(Offset(0, y), Offset(s.width, y), paint);

      _drawText(canvas, '${(level * 100).toStringAsFixed(1)}%', s.width - 60 * dpr, y, const Color(0xFFD4AF37), dpr, fontSize: 8);
    }

    _drawBadge(canvas, 8.0 * dpr, mapY(d.highPrice) - 14 * dpr, dpr);
  }

  void _drawBadge(Canvas canvas, double x, double y, double dpr) {
    final bgPaint = Paint()
      ..color = MehdAiTheme.bgSecondary.withOpacity(0.9);
    final borderPaint = Paint()
      ..color = MehdAiTheme.blue.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5 * dpr;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, 14 * dpr, 10 * dpr),
      Radius.circular(1 * dpr),
    );
    canvas.drawRRect(rect, bgPaint);
    canvas.drawRRect(rect, borderPaint);

    _drawText(canvas, 'M', x + 3 * dpr, y + 5 * dpr, MehdAiTheme.blue, dpr, fontSize: 7, align: Alignment.center);
  }

  void _drawPriceLabel(Canvas canvas, double price, double x, double y, double dpr) {
    _drawText(canvas, price.toStringAsFixed(5), x, y, MehdAiTheme.gold, dpr, fontSize: 8);
  }

  void _drawText(Canvas canvas, String text, double x, double y, Color color, double dpr, {double fontSize = 10, Alignment align = Alignment.bottomLeft}) {
    final builder = ui.ParagraphBuilder(ui.ParagraphStyle(
      textAlign: TextAlign.left,
      fontSize: fontSize * dpr,
      fontWeight: FontWeight.bold,
      fontFamily: 'Courier',
    ))
      ..pushStyle(ui.TextStyle(color: color.withOpacity(0.9)))
      ..addText(text);

    final paragraph = builder.build()
      ..layout(ui.ParagraphConstraints(width: 200 * dpr));
    
    double dx = x;
    double dy = y;
    
    if (align == Alignment.bottomLeft) {
      dy -= paragraph.height + (2 * dpr);
    } else if (align == Alignment.center) {
      dx -= paragraph.width / 2;
      dy -= paragraph.height / 2;
    }
    
    canvas.drawParagraph(paragraph, Offset(dx, dy));
  }

  @override
  bool shouldRepaint(covariant ManualDrawingPainter oldDelegate) {
    return oldDelegate.drawings.length != drawings.length ||
        oldDelegate.drawings.any((d) => d.isSelected) != drawings.any((d) => d.isSelected);
  }
}
