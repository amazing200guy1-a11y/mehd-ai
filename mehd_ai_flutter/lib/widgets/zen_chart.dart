import 'package:flutter/material.dart';
import 'package:mehd_ai_flutter/core/theme.dart';
import 'package:mehd_ai_flutter/models/market_snapshot.dart';
import 'package:mehd_ai_flutter/models/consensus_result.dart';
import 'package:mehd_ai_flutter/widgets/den_animation.dart';

/// FILE 6 — zen_chart.dart
///
/// Build Debrief:
/// This makes Mehd AI completely different from MT4/TradingView.
/// Traditional charts are cluttered with MACD, RSI, Bollinger Bands, etc. 
/// It causes analysis paralysis. In Zen Mode, we remove all of that. 
/// The AI has already processed 9 layers of complex technicals and math natively.
/// Instead of showing the math, we paint the chart with pure, actionable zones.
/// A faint green rectangle = "The AIs think you should buy here." 
/// A faint red rectangle = "Resistance zone."
/// This distills thousands of lines of math into a single, calming visual.

class ZenChart extends StatelessWidget {
  final MarketSnapshot currentPrice;
  final ConsensusResult? currentConsensus;
  final DenState denState;

  const ZenChart({
    super.key,
    required this.currentPrice,
    this.currentConsensus,
    this.denState = DenState.hidden,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: MehdAiTheme.bgPrimary,
      child: Stack(
        children: [
          // 1. The Den Animation Layer (Deep Background)
          Positioned.fill(
            child: DenAnimation(
              state: denState,
              animateModels: denState == DenState.activation,
            ),
          ),

          // 2. The FL Chart (simplified line/candlestick representation)
          Padding(
            padding: const EdgeInsets.only(top: 60.0, bottom: 40, left: 16, right: 16),
            child: CustomPaint(
              size: Size.infinite,
              painter: _CandlestickPainter(
                currentPrice: currentPrice.bid,
                consensus: currentConsensus,
              ),
            ),
          ),

          // Zen Badge
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: MehdAiTheme.bgSecondary.withOpacity(0.8),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: MehdAiTheme.borderColor),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, size: 14, color: MehdAiTheme.purple),
                  const SizedBox(width: 8),
                  Text(
                    'ZEN MODE — AI Zones Active',
                    style: MehdAiTheme.labelStyle.copyWith(color: MehdAiTheme.textPrimary),
                  ),
                ],
              ),
            ),
          ),

          // Live Header Price ticker
          Positioned(
            top: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currentPrice.symbol,
                  style: MehdAiTheme.headingStyle.copyWith(fontSize: 24),
                ),
                Text(
                  currentPrice.bid.toStringAsFixed(5),
                  style: MehdAiTheme.priceStyle.copyWith(fontSize: 28, color: MehdAiTheme.blue),
                ),
                Text(
                  'Spread: ${currentPrice.spread} pips',
                  style: MehdAiTheme.labelStyle,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

}

class _CandlestickPainter extends CustomPainter {
  final double currentPrice;
  final ConsensusResult? consensus;

  _CandlestickPainter({required this.currentPrice, this.consensus});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;

    // 1. Draw AI Zones (Zen Mode background)
    if (consensus != null && consensus!.proceed) {
      final isBuy = consensus!.finalDirection == 'BUY';
      final zoneColor = isBuy ? MehdAiTheme.green : MehdAiTheme.red;
      
      final paint = Paint()
        ..color = zoneColor.withOpacity(0.1)
        ..style = PaintingStyle.fill;

      // Draw active zone
      final rect = isBuy 
        ? Rect.fromLTRB(0, size.height * 0.4, size.width, size.height)
        : Rect.fromLTRB(0, 0, size.width, size.height * 0.6);
        
      canvas.drawRect(rect, paint);
    }

    // 2. Draw Candlesticks
    final candleCount = 30; // 30 candles on screen
    final candleWidth = size.width / candleCount;
    final padding = candleWidth * 0.2;
    final actualWidth = candleWidth - (padding * 2);

    List<_MockCandle> candles = _generateMockCandles(currentPrice, candleCount);
    
    // Find min and max for scaling
    double maxHigh = candles.map((c) => c.high).reduce((a, b) => a > b ? a : b);
    double minLow = candles.map((c) => c.low).reduce((a, b) => a < b ? a : b);
    final range = maxHigh - minLow;
    
    // Add 10% padding top and bottom to range
    maxHigh += range * 0.1;
    minLow -= range * 0.1;
    final scaledRange = maxHigh - minLow;

    final wickPaint = Paint()..strokeWidth = 1.0;
    
    for (int i = 0; i < candleCount; i++) {
      final candle = candles[i];
      final xOffset = i * candleWidth + padding;

      final isBull = candle.close >= candle.open;
      final color = isBull ? MehdAiTheme.green : MehdAiTheme.red;
      
      wickPaint.color = color;
      final bodyPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      // Calculate Y positions (inverted because UI Y goes down)
      final highY = size.height - ((candle.high - minLow) / scaledRange * size.height);
      final lowY = size.height - ((candle.low - minLow) / scaledRange * size.height);
      final openY = size.height - ((candle.open - minLow) / scaledRange * size.height);
      final closeY = size.height - ((candle.close - minLow) / scaledRange * size.height);

      // Draw wick
      canvas.drawLine(
        Offset(xOffset + actualWidth / 2, highY), 
        Offset(xOffset + actualWidth / 2, lowY), 
        wickPaint
      );

      // Draw body
      final topY = isBull ? closeY : openY;
      final bottomY = isBull ? openY : closeY;
      
      // Ensure body has at least 1px height
      final rectHeight = (bottomY - topY).abs() < 1 ? 1.0 : (bottomY - topY);
      
      canvas.drawRect(
        Rect.fromLTWH(xOffset, topY, actualWidth, rectHeight), 
        bodyPaint
      );
    }
    
    // 3. Draw current price line
    final liveY = size.height - ((currentPrice - minLow) / scaledRange * size.height);
    final liveLinePaint = Paint()
      ..color = MehdAiTheme.textPrimary.withOpacity(0.5)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final path = Path();
    for (double x = 0; x < size.width; x += 10) {
      path.moveTo(x, liveY);
      path.lineTo(x + 5, liveY);
    }
    canvas.drawPath(path, liveLinePaint);
  }

  List<_MockCandle> _generateMockCandles(double current, int count) {
    List<_MockCandle> candles = [];
    double walk = current - 0.0050; // Start lower
    
    // Seeded determinism based on the current price so it doesn't flicker wildly
    int seed = (current * 100000).toInt(); 
    
    for (int i = 0; i < count - 1; i++) {
      // Deterministic pseudo-randomness
      double range = 0.0005 + ((seed * i) % 10) * 0.0001; 
      bool isBullish = ((seed + i) % 3) != 0; // 2/3 chance bullish trend
      
      double open = walk;
      double close = isBullish ? open + range : open - (range / 2);
      double high = (open > close ? open : close) + (range * 0.5);
      double low = (open < close ? open : close) - (range * 0.5);
      
      candles.add(_MockCandle(open, close, high, low));
      walk = close;
    }
    
    // Final candle is live 
    double finalOpen = walk;
    double finalClose = current;
    double finalHigh = (finalOpen > finalClose ? finalOpen : finalClose) + 0.0002;
    double finalLow = (finalOpen < finalClose ? finalOpen : finalClose) - 0.0002;
    candles.add(_MockCandle(finalOpen, finalClose, finalHigh, finalLow));
    
    return candles;
  }

  @override
  bool shouldRepaint(covariant _CandlestickPainter oldDelegate) {
    return oldDelegate.currentPrice != currentPrice || 
           oldDelegate.consensus?.finalDirection != consensus?.finalDirection;
  }
}

class _MockCandle {
  final double open, close, high, low;
  _MockCandle(this.open, this.close, this.high, this.low);
}
