import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:mehd_ai_flutter/models/candle.dart';
import 'package:mehd_ai_flutter/models/consensus_result.dart';
import 'package:mehd_ai_flutter/models/chart_enums.dart';
import 'package:mehd_ai_flutter/models/manual_drawing_model.dart';
import 'package:mehd_ai_flutter/models/automated_drawing.dart';
import 'package:mehd_ai_flutter/widgets/den_animation.dart';
import 'package:mehd_ai_flutter/widgets/drawing_engine.dart';

class ZenChartCanvas extends StatelessWidget {
  final List<Candle> candles;
  final double zoomLevel;
  final double scrollOffset;
  final String symbol;
  final double currentPrice;
  final ConsensusResult? consensus;
  final bool isCandles;
  final String timeframe;
  final List<ManualDrawing> manualDrawings;
  final List<AutomatedDrawing> currentDrawings;
  final Animation<double> drawingsAnim;
  final Animation<double> shimmerAnim;
  final DenState denState;
  final DrawingMode drawingMode;
  final DrawingTool activeTool;
  final Function(Offset) onTapDown;
  final Function(ScaleStartDetails) onScaleStart;
  final Function(ScaleUpdateDetails) onScaleUpdate;
  final Function(PointerScrollEvent) onPointerScroll;

  const ZenChartCanvas({
    super.key,
    required this.candles,
    required this.zoomLevel,
    required this.scrollOffset,
    required this.symbol,
    required this.currentPrice,
    this.consensus,
    required this.isCandles,
    required this.timeframe,
    required this.manualDrawings,
    required this.currentDrawings,
    required this.drawingsAnim,
    required this.shimmerAnim,
    required this.denState,
    required this.drawingMode,
    required this.activeTool,
    required this.onTapDown,
    required this.onScaleStart,
    required this.onScaleUpdate,
    required this.onPointerScroll,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Tiger Logo Watermark
        Center(
          child: AnimatedBuilder(
            animation: shimmerAnim,
            builder: (_, child) {
              final isSovereignLock = consensus?.tier == 'sovereign' && consensus?.proceed == true;
              if (!isSovereignLock) {
                return Opacity(opacity: 0.10, child: child);
              }
              return ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [
                    const Color(0xFF58A6FF).withOpacity(0.0),
                    const Color(0xFF58A6FF).withOpacity(0.8),
                    Colors.white.withOpacity(0.9),
                    const Color(0xFF58A6FF).withOpacity(0.8),
                    const Color(0xFF58A6FF).withOpacity(0.0),
                  ],
                  stops: const [0, 0.35, 0.5, 0.65, 1],
                  begin: Alignment(-1 + 2 * shimmerAnim.value, 0),
                  end: Alignment(1 + 2 * shimmerAnim.value, 0),
                ).createShader(bounds),
                child: Opacity(opacity: 0.3, child: child),
              );
            },
            child: Image.asset(
              'assets/images/mehd_logo.png',
              width: 300,
              height: 300,
              fit: BoxFit.contain,
            ),
          ),
        ),

        // 2. Eye Glow Overlay
        Center(
          child: ShaderMask(
            shaderCallback: (rect) {
              return RadialGradient(
                center: const Alignment(0, -0.2),
                radius: 0.2,
                colors: [
                  Colors.white.withOpacity(0.15),
                  Colors.transparent,
                ],
                stops: const [0.4, 1.0],
              ).createShader(rect);
            },
            blendMode: BlendMode.srcATop,
            child: Opacity(
              opacity: 0.05,
              child: Image.asset(
                'assets/images/mehd_logo.png',
                width: 300,
                height: 300,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),

        // 3. The Den Animation Layer
        Positioned.fill(
          child: DenAnimation(
            state: denState,
            animateModels: denState == DenState.activation,
          ),
        ),

        // 4. Core Chart Paint & Gestures
        Padding(
          padding: const EdgeInsets.only(top: 60.0, bottom: 40, left: 16, right: 16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Listener(
                onPointerSignal: (e) {
                  if (e is PointerScrollEvent) onPointerScroll(e);
                },
                child: GestureDetector(
                  onScaleStart: onScaleStart,
                  onScaleUpdate: onScaleUpdate,
                  onTapDown: (d) {
                    if (drawingMode != DrawingMode.manual) return;
                    if (activeTool == DrawingTool.none) return;
                    onTapDown(d.localPosition);
                  },
                  child: SizedBox(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    child: Stack(
                      children: [
                        RepaintBoundary(
                          child: CustomPaint(
                            size: Size(constraints.maxWidth, constraints.maxHeight),
                            painter: ZenChartPainter(
                              candles: candles,
                              zoomLevel: zoomLevel,
                              scrollOffset: scrollOffset,
                              symbol: symbol,
                              currentPrice: currentPrice,
                              consensus: consensus,
                              isCandles: isCandles,
                              timeframe: timeframe,
                              manualDrawings: manualDrawings,
                            ),
                          ),
                        ),
                        RepaintBoundary(
                          child: Opacity(
                            opacity: drawingMode == DrawingMode.manual ? 0.15 : 1.0,
                            child: AnimatedBuilder(
                              animation: drawingsAnim,
                              builder: (context, child) => DrawingEngineOverlay(
                                drawings: currentDrawings,
                                minX: 0,
                                maxX: 30.0,
                                minY: candles.isEmpty ? 0 : candles.map((c) => c.low).reduce(math.min),
                                maxY: candles.isEmpty ? 100 : candles.map((c) => c.high).reduce(math.max),
                                animationValue: drawingsAnim.value,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class ZenChartPainter extends CustomPainter {
  final List<Candle> candles;
  final double zoomLevel;
  final double scrollOffset;
  final String symbol;
  final double currentPrice;
  final ConsensusResult? consensus;
  final bool isCandles;
  final String timeframe;
  final List<ManualDrawing> manualDrawings;

  ZenChartPainter({
    required this.candles,
    required this.zoomLevel,
    required this.scrollOffset,
    required this.symbol,
    required this.currentPrice,
    this.consensus,
    required this.isCandles,
    required this.timeframe,
    required this.manualDrawings,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty || size.width == 0 || size.height == 0) return;

    final dpr = WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
    canvas.save();
    canvas.scale(1 / dpr, 1 / dpr);

    final W = size.width * dpr;
    final H = size.height * dpr;
    final pad = EdgeInsets.fromLTRB(8 * dpr, 12 * dpr, 46 * dpr, 24 * dpr);

    final baseWidth = (size.width / 60) * dpr;
    final candleWidth = baseWidth * zoomLevel;

    final scrollPhysical = scrollOffset * dpr;
    final candlesFromRight = (scrollPhysical / candleWidth).floor().abs();
    final visibleCount = (W / candleWidth).ceil();

    final startIdx = math.max(0, candles.length - visibleCount - candlesFromRight);
    final endIdx = math.min(candles.length, candles.length - candlesFromRight);
    final visibleCandles = candles.sublist(
      startIdx.clamp(0, candles.length),
      endIdx.clamp(0, candles.length),
    );

    if (visibleCandles.isEmpty) {
      canvas.restore();
      return;
    }

    final hi = visibleCandles.map((c) => c.high).reduce(math.max);
    final lo = visibleCandles.map((c) => c.low).reduce(math.min);
    final range = (hi - lo) == 0 ? 0.001 : hi - lo;
    final hiPad = hi + range * 0.08;
    final loPad = lo - range * 0.08;
    final rangePad = hiPad - loPad;

    double px(int i) => pad.left + i * candleWidth + candleWidth / 2;
    double py(double price) => pad.top + (1 - (price - loPad) / rangePad) * (H - pad.top - pad.bottom);

    // AI Zones Background
    if (consensus != null && consensus!.proceed) {
      final isBuy = consensus!.finalDirection == 'BUY';
      final zoneColor = isBuy ? const Color(0xFF00FF88) : const Color(0xFFFF3B3B);
      final paint = Paint()
        ..color = zoneColor.withOpacity(0.05)
        ..style = PaintingStyle.fill;
      final rect = isBuy
          ? Rect.fromLTRB(0, py(lo + range * 0.5), W, H - pad.bottom)
          : Rect.fromLTRB(0, pad.top, W, py(hi - range * 0.5));
      canvas.drawRect(rect, paint);
    }

    // Grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFF0D0D0D)
      ..strokeWidth = 1.0;
    for (int i = 0; i <= 4; i++) {
      final y = pad.top + (i / 4) * (H - pad.top - pad.bottom);
      canvas.drawLine(Offset(pad.left, y), Offset(W - pad.right, y), gridPaint);
    }

    // Time Axis
    final maxTicks = 4;
    final int step = math.max(1, visibleCandles.length ~/ maxTicks);
    for (int i = 0; i < visibleCandles.length; i += step) {
      final x = px(i);
      canvas.drawLine(Offset(x, pad.top), Offset(x, H - pad.bottom), gridPaint);

      final DateTime? time = visibleCandles[i].timestamp;
      if (time == null) continue;

      final isIntraday = timeframe == '1M' || timeframe == '5M' || timeframe == '15M' || timeframe == '1H';
      String timeLabel = '';
      if (isIntraday) {
        timeLabel = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      } else {
        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        timeLabel = '${time.day.toString().padLeft(2, '0')} ${months[time.month - 1]}';
      }

      _drawText(
        canvas,
        timeLabel,
        Offset(x - 14 * dpr, H - pad.bottom + 6 * dpr),
        color: const Color(0xFF333333),
        fontSize: 8 * dpr,
      );
    }

    // Draw candles
    if (isCandles) {
      for (int i = 0; i < visibleCandles.length; i++) {
        final candle = visibleCandles[i];
        final x = px(i);
        final isBull = candle.close >= candle.open;
        final color = isBull ? const Color(0xFF00FF88) : const Color(0xFFFF3B3B);
        final candlePaint = Paint()
          ..color = color
          ..strokeWidth = 1.0
          ..strokeCap = StrokeCap.round;

        canvas.drawLine(Offset(x, py(candle.high)), Offset(x, py(candle.low)), candlePaint);

        final bodyTop = py(math.max(candle.open, candle.close));
        final bodyBot = py(math.min(candle.open, candle.close));
        final bodyHeight = math.max(bodyBot - bodyTop, 1.0);
        final cWidth = math.max(candleWidth * 0.5, 2.0);

        canvas.drawRect(Rect.fromLTWH(x - cWidth / 2, bodyTop, cWidth, bodyHeight), Paint()..color = color);
      }
    } else {
      // Line Chart
      final linePaint = Paint()
        ..color = const Color(0xFF58A6FF)
        ..strokeWidth = 2.0 * dpr
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final path = Path();
      for (int i = 0; i < visibleCandles.length; i++) {
        final xPos = px(i);
        final yPos = py(visibleCandles[i].close);
        if (i == 0) {
          path.moveTo(xPos, yPos);
        } else {
          path.lineTo(xPos, yPos);
        }
      }
      canvas.drawPath(path, linePaint);
    }

    // Current price line
    final priceY = py(currentPrice);
    final isUp = visibleCandles.last.close >= visibleCandles.last.open;
    final pricePaint = Paint()
      ..color = isUp ? const Color(0xFF00FF88) : const Color(0xFFFF3B3B)
      ..strokeWidth = 1.0;

    _drawDashedLine(canvas, Offset(pad.left, priceY), Offset(W - pad.right, priceY), pricePaint);
    canvas.drawRect(Rect.fromLTWH(W - pad.right + 2 * dpr, priceY - 7 * dpr, 46 * dpr, 14 * dpr), pricePaint);

    final dp = currentPrice > 100 ? 2 : 5;
    _drawText(
      canvas,
      currentPrice.toStringAsFixed(dp),
      Offset(W - pad.right + 6 * dpr, priceY - 4.5 * dpr),
      color: const Color(0xFF000000),
      fontSize: 8 * dpr,
      bold: true,
    );

    for (int i = 0; i <= 4; i++) {
      final priceLevel = loPad + rangePad * ((4 - i) / 4);
      _drawText(
        canvas,
        priceLevel.toStringAsFixed(dp),
        Offset(W - pad.right + 4 * dpr, py(priceLevel) - 4 * dpr),
        color: const Color(0xFF1a1a1a),
        fontSize: 7 * dpr,
      );
    }

    _drawManual(canvas, size, manualDrawings);
    canvas.restore();
  }

  void _drawManual(Canvas canvas, Size size, List<ManualDrawing> drawings) {
    for (var d in drawings) {
      if (d.points.isEmpty) continue;
      final p = Paint()
        ..color = d.color
        ..strokeWidth = 1.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      switch (d.type) {
        case DrawingTool.line:
          if (d.points.length < 2) continue;
          canvas.drawLine(d.points[0], d.points[1], p);
          canvas.drawCircle(d.points[0], 4, Paint()..color = d.color);
          canvas.drawCircle(d.points[1], 4, Paint()..color = d.color);
          break;
        case DrawingTool.hline:
          canvas.drawLine(Offset(0, d.points[0].dy), Offset(size.width - 60, d.points[0].dy), p..strokeWidth = 0.8);
          break;
        case DrawingTool.zone:
          if (d.points.length < 2) continue;
          final rect = Rect.fromPoints(d.points[0], d.points[1]);
          canvas.drawRect(rect, Paint()..color = d.color.withOpacity(0.06)..style = PaintingStyle.fill);
          canvas.drawRect(rect, p);
          break;
        case DrawingTool.fib:
          if (d.points.length < 2) continue;
          final top = math.min(d.points[0].dy, d.points[1].dy);
          final bot = math.max(d.points[0].dy, d.points[1].dy);
          final range = bot - top;
          for (var level in [0.0, 0.236, 0.382, 0.5, 0.618, 0.786, 1.0]) {
            final y = top + range * level;
            final isStar = level == 0.618;
            canvas.drawLine(Offset(0, y), Offset(size.width - 60, y), Paint()..color = const Color(0xFFD4AF37).withOpacity(isStar ? 0.7 : 0.25)..strokeWidth = isStar ? 1.2 : 0.5);
          }
          break;
        default: break;
      }
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 4.0;
    const dashSpace = 4.0;
    double distance = 0;
    final total = (end.dx - start.dx);
    while (distance < total) {
      canvas.drawLine(Offset(start.dx + distance, start.dy), Offset(math.min(start.dx + distance + dashWidth, end.dx), end.dy), paint);
      distance += dashWidth + dashSpace;
    }
  }

  void _drawText(Canvas canvas, String text, Offset position, {required Color color, double fontSize = 9, bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, fontWeight: bold ? FontWeight.bold : FontWeight.normal, fontFamily: 'Courier New')),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant ZenChartPainter oldDelegate) {
    return oldDelegate.currentPrice != currentPrice ||
        oldDelegate.zoomLevel != zoomLevel ||
        oldDelegate.scrollOffset != scrollOffset ||
        oldDelegate.symbol != symbol ||
        oldDelegate.consensus?.finalDirection != consensus?.finalDirection ||
        oldDelegate.isCandles != isCandles ||
        oldDelegate.timeframe != timeframe ||
        oldDelegate.manualDrawings.length != manualDrawings.length;
  }
}
