import 'package:flutter/material.dart';

/// Represents the base capability of any automated drawing spawned by the AI.
abstract class AutomatedDrawing {
  final String id;
  final String label;
  final String author; // "TITAN", "ATLAS", "ORACLE", "FORGE"
  final DateTime createdAt;

  AutomatedDrawing({
    required this.id,
    required this.label,
    required this.author,
  }) : createdAt = DateTime.now();
}

// ── CATEGORY 1: Lines ──────────────────────────────────────

enum LineType { support, resistance, trendSupport, trendResistance, structure, channel }

class LineDrawing extends AutomatedDrawing {
  final LineType type;
  final double startX; // logical internal X (0.0 to 1.0 or candle index)
  final double startY; // Price
  final double endX;
  final double endY;
  final int touches;
  final Color color;
  final bool isDashed;

  LineDrawing({
    required super.id,
    required super.label,
    required super.author,
    required this.type,
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    this.touches = 2,
    required this.color,
    this.isDashed = false,
  });
}

// ── CATEGORY 2: Fibonacci (ATLAS) ──────────────────────────

class FibLevel {
  final double ratio;
  final double price;
  final String description;
  final bool isGolden;

  FibLevel(this.ratio, this.price, this.description, {this.isGolden = false});
}

class FibonacciDrawing extends AutomatedDrawing {
  final double startX;
  final double startY; // Swing high/low
  final double endX;
  final double endY;   // Swing low/high
  final List<FibLevel> levels;

  FibonacciDrawing({
    required super.id,
    required super.label,
    required super.author,
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    required this.levels,
  });
}

// ── CATEGORY 3: Zones (ORACLE) ─────────────────────────────

enum ZoneType { supply, demand, fvg, orderBlockBullish, orderBlockBearish, liquidity }

class ZoneDrawing extends AutomatedDrawing {
  final ZoneType type;
  final double startX;
  final double endX;
  final double topPrice;
  final double bottomPrice;
  final Color color;
  final double opacity;
  final bool isDashed;

  ZoneDrawing({
    required super.id,
    required super.label,
    required super.author,
    required this.type,
    required this.startX,
    required this.endX,
    required this.topPrice,
    required this.bottomPrice,
    required this.color,
    this.opacity = 0.05,
    this.isDashed = false,
  });
}

// ── CATEGORY 4: Patterns ───────────────────────────────────

class PatternDrawing extends AutomatedDrawing {
  final String patternName;
  final List<Offset> points; // Coordinates mapping the pattern (e.g. Head & Shoulders)
  final double targetPrice;
  final double probability;

  PatternDrawing({
    required super.id,
    required super.label,
    required super.author,
    required this.patternName,
    required this.points,
    required this.targetPrice,
    required this.probability,
  });
}

// ── CATEGORY 5: AI Exclusive ───────────────────────────────

class ExclusiveMarker extends AutomatedDrawing {
  final double x;
  final double y;
  final Color color;
  final String description;

  ExclusiveMarker({
    required super.id,
    required super.label,
    required super.author,
    required this.x,
    required this.y,
    required this.color,
    required this.description,
  });
}

class KillZoneDrawing extends AutomatedDrawing {
  final double startX;
  final double endX;
  final String sessionName;

  KillZoneDrawing({
    required super.id,
    required super.label,
    required super.author,
    required this.startX,
    required this.endX,
    required this.sessionName,
  });
}
