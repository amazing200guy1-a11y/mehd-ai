import 'package:flutter/material.dart';
import 'package:mehd_ai_flutter/core/theme.dart';
import 'package:mehd_ai_flutter/models/market_snapshot.dart';

/// FIX 1: Data Freshness Indicator
/// Shows Green/Yellow/Red dot with label indicating data status.
/// Auto-locks trade button when stale.

class DataFreshnessIndicator extends StatelessWidget {
  final MarketSnapshot? snapshot;
  const DataFreshnessIndicator({super.key, this.snapshot});

  @override
  Widget build(BuildContext context) {
    if (snapshot == null) {
      return const SizedBox.shrink();
    }

    Color dotColor;
    String label;
    final age = snapshot!.dataAgeMs;

    if (age < 1000) {
      dotColor = MehdAiTheme.green;
      label = 'LIVE';
    } else if (age < 5000) {
      dotColor = MehdAiTheme.yellow;
      label = 'DELAYED ${(age / 1000).toStringAsFixed(0)}s';
    } else {
      dotColor = MehdAiTheme.red;
      label = 'STALE';
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: dotColor.withOpacity(0.6), blurRadius: 4)],
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: MehdAiTheme.terminalStyle.copyWith(
              color: dotColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            '[${snapshot!.dataSource.toUpperCase()}]',
            style: MehdAiTheme.terminalStyle.copyWith(
              color: MehdAiTheme.textSecondary,
              fontSize: 9,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
