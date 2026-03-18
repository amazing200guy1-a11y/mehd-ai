import 'package:flutter/material.dart';
import 'package:mehd_ai_flutter/core/theme.dart';
import 'package:mehd_ai_flutter/models/consensus_result.dart';

/// FILE 8 — consensus_bar.dart
///
/// Build Debrief:
/// This is the singular interaction point for placing a trade. 
/// In traditional apps, you have complex order tickets. Here, the AI has already
/// determined the direction, and the HardRiskKernel determines the lot size and 
/// stop loss behind the scenes. This button only unlocks when the mathematical threshold 
/// (70% consensus) is reached. It visually communicates "Wait" vs "Execute".

enum ButtonState { locked, readyBuy, readySell, executing, filled, developing, vetoed }

class ConsensusBar extends StatelessWidget {
  final ConsensusResult? consensus;
  final ButtonState buttonState;
  final VoidCallback onTradePressed;

  const ConsensusBar({
    super.key,
    this.consensus,
    required this.buttonState,
    required this.onTradePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: const BoxDecoration(
        color: MehdAiTheme.bgSecondary,
        border: Border(top: BorderSide(color: MehdAiTheme.borderColor)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Consensus Score
          _buildScoreSection(),
          
          // Center: Risk Pill
          _buildRiskPill(),
          
          // Right: Action Button
          _buildTradeButton(),
        ],
      ),
    );
  }

  Widget _buildScoreSection() {
    if (consensus == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('--%', style: MehdAiTheme.priceStyle.copyWith(color: MehdAiTheme.textSecondary, fontSize: 20)),
          Text('Awaiting Market', style: MehdAiTheme.labelStyle.copyWith(fontSize: 10)),
        ],
      );
    }

    final isBuy = consensus!.finalDirection == 'BUY';
    final isSell = consensus!.finalDirection == 'SELL';
    final color = isBuy ? MehdAiTheme.green : (isSell ? MehdAiTheme.red : MehdAiTheme.yellow);
    final count = consensus!.votes.where((v) => v.direction == consensus!.finalDirection).length;
    final total = consensus!.votes.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${consensus!.consensusPercentage.toStringAsFixed(0)}% ${consensus!.finalDirection}',
          style: MehdAiTheme.priceStyle.copyWith(color: color, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          'The Den agrees — $count/$total predators',
          style: MehdAiTheme.labelStyle.copyWith(fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildRiskPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: MehdAiTheme.bgPrimary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: MehdAiTheme.borderColor),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield, size: 14, color: MehdAiTheme.purple),
          const SizedBox(width: 8),
          Text('Max risk: 1% | SL: auto', style: MehdAiTheme.labelStyle.copyWith(color: MehdAiTheme.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildTradeButton() {
    Color bgColor;
    Color borderColor;
    String text;
    bool enabled = false;
    Widget? icon;

    switch (buttonState) {
      case ButtonState.locked:
        bgColor = MehdAiTheme.bgTertiary;
        borderColor = MehdAiTheme.borderColor;
        text = 'LOCKED — The Den is thinking';
        icon = const Icon(Icons.lock, size: 16, color: MehdAiTheme.textSecondary);
        break;
      case ButtonState.developing:
        bgColor = MehdAiTheme.yellow.withOpacity(0.1);
        borderColor = MehdAiTheme.yellow;
        text = '6/9 — Trend Forming. Monitoring...';
        enabled = false;
        icon = const Icon(Icons.sync, size: 16, color: MehdAiTheme.yellow);
        break;
      case ButtonState.vetoed:
        bgColor = MehdAiTheme.bgTertiary;
        borderColor = MehdAiTheme.borderColor;
        text = 'Math Layer Veto — Market unsafe';
        enabled = false;
        icon = const Icon(Icons.block, size: 16, color: MehdAiTheme.textSecondary);
        break;
      case ButtonState.readyBuy:
        bgColor = MehdAiTheme.green.withOpacity(0.1);
        borderColor = MehdAiTheme.green;
        text = 'EXECUTE BUY';
        enabled = true;
        break;
      case ButtonState.readySell:
        bgColor = MehdAiTheme.red.withOpacity(0.1);
        borderColor = MehdAiTheme.red;
        text = 'EXECUTE SELL';
        enabled = true;
        break;
      case ButtonState.executing:
        bgColor = MehdAiTheme.blue.withOpacity(0.1);
        borderColor = MehdAiTheme.blue;
        text = 'EXECUTING...';
        enabled = false;
        icon = SizedBox(
          width: 14, height: 14,
          child: Opacity(opacity: 0.5, child: Image.asset('assets/images/mehd_logo.png')),
        );
        break;
      case ButtonState.filled:
        bgColor = MehdAiTheme.green.withOpacity(0.2);
        borderColor = MehdAiTheme.green;
        text = 'ORDER FILLED';
        enabled = false;
        icon = const Icon(Icons.check, size: 16, color: MehdAiTheme.green);
        break;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 240,
      height: 44,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor),
      ),
      child: InkWell(
        onTap: enabled ? onTradePressed : null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[icon, const SizedBox(width: 8)],
            Text(
              text,
              style: MehdAiTheme.headingStyle.copyWith(
                fontSize: 13,
                color: enabled ? borderColor : MehdAiTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
