import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:mehd_ai_flutter/models/automated_drawing.dart';
import 'package:mehd_ai_flutter/models/candle.dart';

class DrawingEngine {
  
  static List<AutomatedDrawing> generateDrawings(
      List<Candle> candles, double minX, double maxX, double minY, double maxY, 
      Map<String, bool> activeToggles) {
    
    final List<AutomatedDrawing> drawings = [];
    if (candles.isEmpty) return drawings;

    // ── CATEGORY 1: Trendlines (TITAN) ──
    if (activeToggles['Lines'] == true) {
      final swingLows = _findSwingPoints(candles, isHigh: false);
      if (swingLows.length >= 2) {
        final lastTwo = swingLows.sublist(math.max(0, swingLows.length - 2));
        drawings.add(LineDrawing(
          id: 'L_Trend_Supp', label: 'ASCENDING SUPPORT', author: 'TITAN',
          type: LineType.trendSupport, 
          startX: lastTwo[0].index.toDouble(), startY: lastTwo[0].price,
          endX: maxX, endY: _extendLine(lastTwo[0], lastTwo[1], maxX),
          color: const Color.fromRGBO(0, 255, 136, 0.55), isDashed: false,
        ));
      }

      final swingHighs = _findSwingPoints(candles, isHigh: true);
      if (swingHighs.length >= 2) {
        final lastTwo = swingHighs.sublist(math.max(0, swingHighs.length - 2));
        drawings.add(LineDrawing(
          id: 'L_Trend_Res', label: 'DESCENDING RESISTANCE', author: 'TITAN',
          type: LineType.trendResistance, 
          startX: lastTwo[0].index.toDouble(), startY: lastTwo[0].price,
          endX: maxX, endY: _extendLine(lastTwo[0], lastTwo[1], maxX),
          color: const Color.fromRGBO(255, 59, 59, 0.55), isDashed: false,
        ));
      }
    }

    // ── CATEGORY 2: S/R Lines ──
    if (activeToggles['Lines'] == true) {
      final last30 = candles.sublist(math.max(0, candles.length - 30));
      if (last30.isNotEmpty) {
        double highestClose = last30.map((c) => c.close).reduce(math.max);
        double lowestClose = last30.map((c) => c.close).reduce(math.min);

        drawings.add(LineDrawing(
          id: 'L_Horiz_Res', label: 'RESISTANCE', author: 'TITAN',
          type: LineType.resistance, startX: minX, endX: maxX,
          startY: highestClose, endY: highestClose,
          color: const Color.fromRGBO(255, 59, 59, 0.5), isDashed: true,
        ));

        drawings.add(LineDrawing(
          id: 'L_Horiz_Supp', label: 'SUPPORT', author: 'TITAN',
          type: LineType.support, startX: minX, endX: maxX,
          startY: lowestClose, endY: lowestClose,
          color: const Color.fromRGBO(0, 255, 136, 0.5), isDashed: true,
        ));
      }
    }

    // ── CATEGORY 3: Fibonacci (ATLAS) ──
    if (activeToggles['Fibonacci'] == true) {
      double high = candles.map((c) => c.high).reduce(math.max);
      double low = candles.map((c) => c.low).reduce(math.min);
      double diff = high - low;

      final levels = [
        FibLevel(0.236, low + diff * 0.236, "23.6%"),
        FibLevel(0.382, low + diff * 0.382, "38.2%"),
        FibLevel(0.500, low + diff * 0.500, "50%"),
        FibLevel(0.618, low + diff * 0.618, "61.8% \u2605", isGolden: true),
        FibLevel(0.786, low + diff * 0.786, "78.6%"),
      ];

      drawings.add(FibonacciDrawing(
        id: 'F_Fib', label: 'FIB LEVELS', author: 'ATLAS',
        startX: minX, startY: high,
        endX: maxX, endY: low,
        levels: levels,
      ));
    }

    // ── CATEGORY 4: FVGs (ORACLE) ──
    if (activeToggles['Zones'] == true) {
      for (int i = 2; i < candles.length; i++) {
        // Bullish FVG
        if (candles[i].low > candles[i - 2].high) {
          drawings.add(ZoneDrawing(
            id: 'Z_FVG_Bull_$i', label: 'FVG \u2191', author: 'ORACLE',
            type: ZoneType.fvg,
            startX: (i - 2).toDouble(), endX: (i).toDouble() + 5,
            topPrice: candles[i].low, bottomPrice: candles[i - 2].high,
            color: const Color(0xFF58A6FF), opacity: 0.06,
          ));
        }
        // Bearish FVG
        if (candles[i].high < candles[i - 2].low) {
          drawings.add(ZoneDrawing(
            id: 'Z_FVG_Bear_$i', label: 'FVG \u2193', author: 'ORACLE',
            type: ZoneType.fvg,
            startX: (i - 2).toDouble(), endX: (i).toDouble() + 5,
            topPrice: candles[i - 2].low, bottomPrice: candles[i].high,
            color: const Color(0xFFFF6B00), opacity: 0.06,
          ));
        }
      }
    }

    return drawings;
  }

  static List<_SwingPoint> _findSwingPoints(List<Candle> candles, {required bool isHigh}) {
    List<_SwingPoint> points = [];
    for (int i = 3; i < candles.length - 3; i++) {
      bool isSwing = true;
      for (int j = 1; j <= 3; j++) {
        if (isHigh) {
          if (candles[i].high <= candles[i - j].high || candles[i].high <= candles[i + j].high) {
            isSwing = false;
            break;
          }
        } else {
          if (candles[i].low >= candles[i - j].low || candles[i].low >= candles[i + j].low) {
            isSwing = false;
            break;
          }
        }
      }
      if (isSwing) {
        points.add(_SwingPoint(i, isHigh ? candles[i].high : candles[i].low));
      }
    }
    return points;
  }

  static double _extendLine(_SwingPoint p1, _SwingPoint p2, double targetX) {
    if (p2.index == p1.index) return p1.price;
    double slope = (p2.price - p1.price) / (p2.index - p1.index);
    return p1.price + slope * (targetX - p1.index);
  }
}

class _SwingPoint {
  final int index;
  final double price;
  _SwingPoint(this.index, this.price);
}
