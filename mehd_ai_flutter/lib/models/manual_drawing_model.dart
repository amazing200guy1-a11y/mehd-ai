import 'dart:ui';
import 'package:mehd_ai_flutter/models/chart_enums.dart';

class ManualDrawing {
  final DrawingTool type;
  final List<Offset> points;
  final Color color;

  ManualDrawing({
    required this.type,
    required this.points,
    required this.color,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.index,
      'points': points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
      'color': color.value,
    };
  }

  factory ManualDrawing.fromJson(Map<String, dynamic> json) {
    return ManualDrawing(
      type: DrawingTool.values[json['type'] as int],
      points: (json['points'] as List).map((p) => Offset(p['x'], p['y'])).toList(),
      color: Color(json['color'] as int),
    );
  }
}
