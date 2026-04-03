import 'dart:ui';

/// Manual drawing models for user-created chart annotations.
/// These are separate from AutomatedDrawing (AI-generated) and carry
/// an "M" badge vs "AI" badge for visual distinction.

enum ManualDrawingTool { trendline, horizontalLine, zone, fibonacci, none }

abstract class ManualDrawing {
  final String id;
  final DateTime createdAt;
  bool isSelected;

  ManualDrawing({required this.id, this.isSelected = false})
      : createdAt = DateTime.now();

  Map<String, dynamic> toJson();

  static ManualDrawing fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    final id = json['id'] as String;
    switch (type) {
      case 'trendline':
        return ManualTrendline(
          id: id,
          startX: (json['startX'] as num).toDouble(),
          startY: (json['startY'] as num).toDouble(),
          endX: (json['endX'] as num).toDouble(),
          endY: (json['endY'] as num).toDouble(),
        );
      case 'horizontalLine':
        return ManualHorizontalLine(
          id: id,
          priceLevel: (json['priceLevel'] as num).toDouble(),
        );
      case 'zone':
        return ManualZone(
          id: id,
          topPrice: (json['topPrice'] as num).toDouble(),
          bottomPrice: (json['bottomPrice'] as num).toDouble(),
        );
      case 'fibonacci':
        return ManualFibonacci(
          id: id,
          highPrice: (json['highPrice'] as num).toDouble(),
          lowPrice: (json['lowPrice'] as num).toDouble(),
        );
      default:
        throw Exception('Unknown drawing type: $type');
    }
  }
}

class ManualTrendline extends ManualDrawing {
  double startX, startY, endX, endY;

  ManualTrendline({
    required super.id,
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
  });

  @override
  Map<String, dynamic> toJson() => {
    'type': 'trendline',
    'id': id,
    'startX': startX,
    'startY': startY,
    'endX': endX,
    'endY': endY,
  };

  bool hitTest(Offset point, Size chartSize, double minX, double maxX, double minY, double maxY) {
    double mX(double x) => chartSize.width * ((x - minX) / (maxX - minX));
    double mY(double y) => chartSize.height * (1.0 - ((y - minY) / (maxY - minY)));
    final p1 = Offset(mX(startX), mY(startY));
    final p2 = Offset(mX(endX), mY(endY));
    return _distToSegment(point, p1, p2) < 20.0;
  }
}

class ManualHorizontalLine extends ManualDrawing {
  /// Price level for the horizontal line.
  double priceLevel;

  ManualHorizontalLine({required super.id, required this.priceLevel});

  bool hitTest(Offset point, Size chartSize, double minX, double maxX, double minY, double maxY) {
    double mY(double y) => chartSize.height * (1.0 - ((y - minY) / (maxY - minY)));
    final lineY = mY(priceLevel);
    return (point.dy - lineY).abs() < 15.0;
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': 'horizontalLine',
    'id': id,
    'priceLevel': priceLevel,
  };
}

class ManualZone extends ManualDrawing {
  /// Top and bottom price levels.
  double topPrice, bottomPrice;

  ManualZone({required super.id, required this.topPrice, required this.bottomPrice});

  bool hitTest(Offset point, Size chartSize, double minX, double maxX, double minY, double maxY) {
    double mY(double y) => chartSize.height * (1.0 - ((y - minY) / (maxY - minY)));
    final top = mY(topPrice);
    final bot = mY(bottomPrice);
    return point.dy >= top && point.dy <= bot;
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': 'zone',
    'id': id,
    'topPrice': topPrice,
    'bottomPrice': bottomPrice,
  };
}

class ManualFibonacci extends ManualDrawing {
  /// Swing high and swing low price levels.
  double highPrice, lowPrice;

  ManualFibonacci({required super.id, required this.highPrice, required this.lowPrice});

  static const List<double> levels = [0.0, 0.236, 0.382, 0.5, 0.618, 0.786, 1.0];

  bool hitTest(Offset point, Size chartSize, double minX, double maxX, double minY, double maxY) {
    double mY(double y) => chartSize.height * (1.0 - ((y - minY) / (maxY - minY)));
    for (final level in levels) {
      final price = lowPrice + (highPrice - lowPrice) * level;
      final lineY = mY(price);
      if ((point.dy - lineY).abs() < 12.0) return true;
    }
    return false;
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': 'fibonacci',
    'id': id,
    'highPrice': highPrice,
    'lowPrice': lowPrice,
  };
}

/// Distance from point P to line segment AB.
double _distToSegment(Offset p, Offset a, Offset b) {
  final ab = b - a;
  final ap = p - a;
  final lenSq = ab.dx * ab.dx + ab.dy * ab.dy;
  if (lenSq == 0) return (p - a).distance;
  double t = (ap.dx * ab.dx + ap.dy * ab.dy) / lenSq;
  t = t.clamp(0.0, 1.0);
  final proj = Offset(a.dx + t * ab.dx, a.dy + t * ab.dy);
  return (p - proj).distance;
}
