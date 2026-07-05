import 'package:flutter/material.dart';
import 'package:mehd_ai_flutter/core/theme.dart';

/// The 5-color semantic language of the War Room.
/// ONE color = ONE meaning. No exceptions.
///
///   Green  = BUY
///   Red    = SELL
///   Grey   = HOLD / Idle
///   Amber  = Alert / Pay Attention
///   Blue   = System Working / Analyzing
///
enum WarRoomState {
  idle,
  analyzing,
  alert,
  verdictBuy,
  verdictSell
}

extension WarRoomStateColors on WarRoomState {
  /// The single semantic color for this state.
  Color get color {
    switch (this) {
      case WarRoomState.idle:
        return MehdAiTheme.grey;
      case WarRoomState.analyzing:
        return MehdAiTheme.blue;
      case WarRoomState.alert:
        return MehdAiTheme.amber;
      case WarRoomState.verdictBuy:
        return MehdAiTheme.green;
      case WarRoomState.verdictSell:
        return MehdAiTheme.red;
    }
  }

  /// Directional icon — gives colorblind users a redundant channel.
  /// Always pair with [color] when rendering a verdict/state indicator.
  IconData get icon {
    switch (this) {
      case WarRoomState.idle:
        return Icons.remove; // ─ flat: nothing happening
      case WarRoomState.analyzing:
        return Icons.sync; // ↻ rotating: system working
      case WarRoomState.alert:
        return Icons.warning_amber_rounded; // ⚠ triangle: pay attention
      case WarRoomState.verdictBuy:
        return Icons.arrow_upward; // ↑ up arrow: BUY
      case WarRoomState.verdictSell:
        return Icons.arrow_downward; // ↓ down arrow: SELL
    }
  }

  /// Short human-readable label for this state.
  String get label {
    switch (this) {
      case WarRoomState.idle:
        return 'HOLD';
      case WarRoomState.analyzing:
        return 'ANALYZING';
      case WarRoomState.alert:
        return 'ALERT';
      case WarRoomState.verdictBuy:
        return 'BUY';
      case WarRoomState.verdictSell:
        return 'SELL';
    }
  }

  /// Whether this state represents an actionable trading verdict.
  bool get isVerdict =>
      this == WarRoomState.verdictBuy || this == WarRoomState.verdictSell;
}
