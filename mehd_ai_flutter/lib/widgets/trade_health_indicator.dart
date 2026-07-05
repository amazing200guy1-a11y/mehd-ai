import 'package:flutter/material.dart';
import 'package:mehd_ai_flutter/core/theme.dart';

/// FILE — trade_health_indicator.dart
/// 
/// PURPOSE:
/// Fulfills Rule 6 (Trade Health Scoring) and Rule 9 (UI Must Reflect Reality).
/// DERIVED FROM: spread deterioration, volatility spikes, RR degradation, time decay.
/// This widget provides a compact "Heartrate" visualization for active trades.

class TradeHealthIndicator extends StatefulWidget {
  final int healthScore;
  final bool isPulsing;

  const TradeHealthIndicator({
    super.key,
    required this.healthScore,
    this.isPulsing = true,
  });

  @override
  State<TradeHealthIndicator> createState() => _TradeHealthIndicatorState();
}

class _TradeHealthIndicatorState extends State<TradeHealthIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color healthColor;
    String statusLabel;

    if (widget.healthScore >= 80) {
      healthColor = MehdAiTheme.blue;
      statusLabel = 'OPTIMAL';
    } else if (widget.healthScore >= 60) {
      healthColor = MehdAiTheme.green;
      statusLabel = 'STABLE';
    } else if (widget.healthScore >= 35) {
      healthColor = MehdAiTheme.amber;
      statusLabel = 'DETERIORATING';
    } else {
      healthColor = MehdAiTheme.red;
      statusLabel = 'CRITICAL';
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              statusLabel,
              style: MehdAiTheme.terminalStyle.copyWith(
                fontSize: 8,
                color: healthColor.withOpacity(0.7),
                letterSpacing: 1,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 6),
            ScaleTransition(
              scale: widget.isPulsing ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
              child: Icon(
                Icons.favorite,
                size: 10,
                color: healthColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          width: 60,
          height: 3,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerRight,
            widthFactor: widget.healthScore / 100,
            child: Container(
              decoration: BoxDecoration(
                color: healthColor,
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                    color: healthColor.withOpacity(0.5),
                    blurRadius: 4,
                  )
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'VITALITY: ${widget.healthScore}%',
          style: MehdAiTheme.terminalStyle.copyWith(
            fontSize: 9,
            color: Colors.white.withOpacity(0.5),
            fontFamily: 'JetBrains Mono',
          ),
        ),
      ],
    );
  }
}
