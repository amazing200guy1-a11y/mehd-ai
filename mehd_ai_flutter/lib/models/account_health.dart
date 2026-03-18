/// FILE 4c — account_health.dart
///
/// Build Debrief:
/// This file models the state of the user's account and the risk engine's decisions.
/// By mirroring the FastAPI models exactly, the Flutter app understands the 
/// HardRiskKernel's kill-switch state natively. We also define TradeOrder here
/// since it's fundamentally about risk and execution.

import 'package:mehd_ai_flutter/models/consensus_result.dart';

class AccountHealth {
  final double balance;
  final double equity;
  final double dailyDrawdownPct;
  final bool isLocked;
  final String? lockReason;
  final DateTime? lockExpiry;

  AccountHealth({
    required this.balance,
    required this.equity,
    required this.dailyDrawdownPct,
    required this.isLocked,
    this.lockReason,
    this.lockExpiry,
  });

  factory AccountHealth.fromJson(Map<String, dynamic> json) {
    return AccountHealth(
      balance: (json['balance'] as num).toDouble(),
      equity: (json['equity'] as num).toDouble(),
      dailyDrawdownPct: (json['daily_drawdown_pct'] as num).toDouble(),
      isLocked: json['is_locked'] as bool,
      lockReason: json['lock_reason'] as String?,
      lockExpiry: json['lock_expiry'] != null
          ? DateTime.parse(json['lock_expiry'] as String)
          : null,
    );
  }
}

class TradeOrder {
  final String symbol;
  final String direction;
  final double lotSize;
  final double? stopLoss;
  final double? takeProfit;
  final double riskPercentage;
  final List<AIVote>? votes;

  TradeOrder({
    required this.symbol,
    required this.direction,
    required this.lotSize,
    this.stopLoss,
    this.takeProfit,
    this.riskPercentage = 1.0,
    this.votes,
  });

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'direction': direction,
      'lot_size': lotSize,
      'stop_loss': stopLoss,
      'take_profit': takeProfit,
      'risk_percentage': riskPercentage,
      if (votes != null) 'votes': votes!.map((v) => v.toJson()).toList(),
    };
  }
}

class RiskDecision {
  final String id;
  final bool approved;
  final double calculatedLotSize;
  final double stopLoss;
  final double? takeProfit;
  final String? rejectionReason;
  final DateTime timestamp;

  RiskDecision({
    required this.id,
    required this.approved,
    required this.calculatedLotSize,
    required this.stopLoss,
    this.takeProfit,
    this.rejectionReason,
    required this.timestamp,
  });

  factory RiskDecision.fromJson(Map<String, dynamic> json) {
    return RiskDecision(
      id: json['id'] as String,
      approved: json['approved'] as bool,
      calculatedLotSize: (json['calculated_lot_size'] as num).toDouble(),
      stopLoss: (json['stop_loss'] as num).toDouble(),
      takeProfit: json['take_profit'] != null ? (json['take_profit'] as num).toDouble() : null,
      rejectionReason: json['rejection_reason'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
