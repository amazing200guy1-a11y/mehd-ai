import 'package:flutter/material.dart';

class TitanAnimations {
  // Google Material 3 emphasized curve
  static const emphasized = Cubic(0.2, 0.0, 0.0, 1.0);
  
  // SpaceX precision curve
  static const precision = Cubic(0.4, 0.0, 0.2, 1.0);
  
  // OpenAI smooth curve
  static const smooth = Cubic(0.25, 0.1, 0.25, 1.0);
  
  // Durations
  static const fast = Duration(milliseconds: 150);
  static const medium = Duration(milliseconds: 300);
  static const slow = Duration(milliseconds: 500);
}
