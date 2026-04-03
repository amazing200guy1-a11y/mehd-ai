import 'package:flutter/material.dart';
import 'package:mehd_ai_flutter/core/theme.dart';

class QuickPipCalculator extends StatefulWidget {
  const QuickPipCalculator({super.key});

  @override
  State<QuickPipCalculator> createState() => _QuickPipCalculatorState();
}

class _QuickPipCalculatorState extends State<QuickPipCalculator> {
  bool _isExpanded = false;
  double _riskAmount = 100.0;
  double _stopLossPips = 20.0;
  final double _accountBalance = 10000.0; // Mock account balance

  double get _maxRisk => _accountBalance * 0.01; // 1% max

  @override
  Widget build(BuildContext context) {
    if (!_isExpanded) {
      return FloatingActionButton.small(
        backgroundColor: MehdAiTheme.bgSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: MehdAiTheme.borderColor),
        ),
        onPressed: () => setState(() => _isExpanded = true),
        child: const Icon(Icons.calculate, color: MehdAiTheme.blue, size: 20),
      );
    }

    final lotSize = _riskAmount / (_stopLossPips * 10); // Rough approximation for standard lots

    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MehdAiTheme.bgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MehdAiTheme.borderColor),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: Text('PIP CALCULATOR', style: MehdAiTheme.labelStyle.copyWith(color: MehdAiTheme.white), overflow: TextOverflow.ellipsis)),
              InkWell(
                onTap: () => setState(() => _isExpanded = false),
                child: const Icon(Icons.close, size: 16, color: MehdAiTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Risk Amount (\$)', style: MehdAiTheme.labelStyle, overflow: TextOverflow.ellipsis),
          Slider(
            value: _riskAmount.clamp(10, _maxRisk),
            min: 10,
            max: _maxRisk,
            divisions: (_maxRisk / 10).round().clamp(1, 100),
            activeColor: MehdAiTheme.blue,
            inactiveColor: MehdAiTheme.borderColor,
            label: '\$${_riskAmount.toInt()}',
            onChanged: (val) => setState(() => _riskAmount = val),
          ),
          Text('1% cap: \$${_maxRisk.toInt()} of \$${_accountBalance.toInt()} account', style: MehdAiTheme.labelStyle.copyWith(color: MehdAiTheme.yellow, fontSize: 9), overflow: TextOverflow.ellipsis),
          Text('Stop Loss (Pips)', style: MehdAiTheme.labelStyle, overflow: TextOverflow.ellipsis),
          Slider(
            value: _stopLossPips,
            min: 5,
            max: 100,
            divisions: 95,
            activeColor: MehdAiTheme.red,
            inactiveColor: MehdAiTheme.borderColor,
            label: '${_stopLossPips.toInt()} pips',
            onChanged: (val) => setState(() => _stopLossPips = val),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: MehdAiTheme.bgPrimary,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: MehdAiTheme.borderColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: Text('Lot Size:', style: MehdAiTheme.labelStyle, overflow: TextOverflow.ellipsis)),
                Flexible(
                  child: Text(
                    lotSize.toStringAsFixed(2),
                    style: MehdAiTheme.terminalStyle.copyWith(color: MehdAiTheme.green, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
