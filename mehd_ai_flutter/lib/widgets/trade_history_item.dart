import 'package:flutter/material.dart';
import 'package:mehd_ai_flutter/core/theme.dart';
import 'package:mehd_ai_flutter/models/trade.dart';
import 'package:intl/intl.dart';


class TradeHistoryItem extends StatelessWidget {
  final Trade trade;

  const TradeHistoryItem({super.key, required this.trade});

  @override
  Widget build(BuildContext context) {
    final isProfit = trade.pnl >= 0;
    final pnlColor = isProfit ? MehdAiTheme.green : MehdAiTheme.red;
    final pnlText = isProfit 
        ? '+\$${trade.pnl.toStringAsFixed(2)}' 
        : '-\$${trade.pnl.abs().toStringAsFixed(2)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: MehdAiTheme.bgSecondary,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: MehdAiTheme.borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Symbol and Time
          Flexible(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: trade.direction == 'BUY' ? MehdAiTheme.green : MehdAiTheme.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        trade.symbol, 
                        style: MehdAiTheme.terminalStyle.copyWith(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        trade.direction, 
                        style: MehdAiTheme.labelStyle, 
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMM d, HH:mm:ss').format(trade.timestamp), 
                  style: MehdAiTheme.labelStyle.copyWith(fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 8),

          // Middle: Consensus Score (Flexible wrapper)
          Flexible(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: MehdAiTheme.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '✓ Verified ${trade.consensusScore.toStringAsFixed(0)}%',
                style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.blue, fontSize: 10),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          
          const SizedBox(width: 8),

          // Right: PnL
          Flexible(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(pnlText, style: MehdAiTheme.priceStyle.copyWith(color: pnlColor, fontSize: 14)),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('@ ${trade.entryPrice.toStringAsFixed(4)}', style: MehdAiTheme.labelStyle.copyWith(fontSize: 10)),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
