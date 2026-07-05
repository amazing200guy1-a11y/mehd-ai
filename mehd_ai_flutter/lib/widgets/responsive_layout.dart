import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ResponsiveLayout({
    super.key,
    required this.child,
    this.maxWidth = 800.0,
  });

  @override
  Widget build(BuildContext context) {
    // If the screen is wider than the assigned maximum width, clamp it and map it to the center.
    // If it's smaller (like a mobile phone), the Container naturally passes through as full width.
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
