import 'package:flutter/material.dart';
import 'package:mehd_ai_flutter/core/theme.dart';

/// TechnoCard — The MEHD AI premium metallic card component.
///
/// Designed to replicate the "cold-milled aluminium" aesthetic:
/// a solid, chunky card that looks like physical machined metal
/// sitting on a pure black surface. The depth comes from:
///   1. A precise multi-stop vertical gradient (lighter at top, darker at bottom)
///   2. A bright top-edge "light catch" — 1px highlight simulating reflected ceiling light
///   3. A subtly lighter left edge and darker right/bottom edges for 3D depth
///   4. A deep drop sandbox for physical elevation above the surface
///   5. ClipRRect to guarantee perfectly smooth corners — no bleeding edges
class TechnoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;
  final double radius;

  const TechnoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderColor,
    this.radius = MehdAiTheme.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    const topHighlight = Color(0xFF5C6070); // Bright silver-grey edge
    const leftHighlight = Color(0xFF44474F);
    const rightEdge = Color(0xFF111215);
    const bottomEdge = Color(0xFF0D0E10);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(
            color: Color(0xBF000000),
            blurRadius: 28,
            offset: Offset(0, 14),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      // ClipRRect is THE fix — it enforces the rounded corners hard,
      // preventing any gradient or border from bleeding outside the radius.
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF3E4149),
                Color(0xFF2E3038),
                Color(0xFF232630),
                Color(0xFF1A1C23),
              ],
              stops: [0.0, 0.35, 0.7, 1.0],
            ),
          ),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              // REMOVED borderRadius: BorderRadius.circular(radius) because Flutter
              // throws an assertion when combining borderRadius with non-uniform Border.
              // ClipRRect already handles the corner rounding.
              border: Border(
                top: BorderSide(color: topHighlight, width: 1.0),
                left: BorderSide(color: leftHighlight, width: 0.5),
                right: BorderSide(color: rightEdge, width: 0.5),
                bottom: BorderSide(color: bottomEdge, width: 1.0),
              ),
            ),
            child: Container(
              padding: padding,
              child: borderColor != null
                  ? DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(color: borderColor!, width: 3),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: child,
                      ),
                    )
                  : child,
            ),
          ),
        ),
      ),
    );
  }
}
