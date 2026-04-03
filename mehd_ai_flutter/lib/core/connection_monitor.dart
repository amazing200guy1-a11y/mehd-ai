import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mehd_ai_flutter/core/constants.dart';

/// FIX 5: Connection quality detection and adaptive behaviour.
/// Automatically detects connection speed and adjusts UI/data accordingly.

enum ConnectionQuality { fast, medium, slow, offline }

class ConnectionMonitor extends ChangeNotifier {
  ConnectionQuality _quality = ConnectionQuality.fast;
  Timer? _timer;

  ConnectionQuality get quality => _quality;

  bool get isTradingSafe => _quality == ConnectionQuality.fast || _quality == ConnectionQuality.medium;

  int get priceUpdateInterval {
    switch (_quality) {
      case ConnectionQuality.fast:
        return 100;
      case ConnectionQuality.medium:
        return 300;
      case ConnectionQuality.slow:
        return 500;
      case ConnectionQuality.offline:
        return 0;
    }
  }

  int get chartCandleCount {
    switch (_quality) {
      case ConnectionQuality.fast:
        return 100;
      case ConnectionQuality.medium:
        return 60;
      case ConnectionQuality.slow:
        return 30;
      case ConnectionQuality.offline:
        return 0;
    }
  }

  String get warningMessage {
    switch (_quality) {
      case ConnectionQuality.fast:
        return '';
      case ConnectionQuality.medium:
        return 'Medium connection — slight delays possible';
      case ConnectionQuality.slow:
        return 'Slow connection detected — paper trading recommended';
      case ConnectionQuality.offline:
        return 'Offline — all trading locked';
    }
  }

  IconData get statusIcon {
    switch (_quality) {
      case ConnectionQuality.fast:
        return Icons.wifi;
      case ConnectionQuality.medium:
        return Icons.wifi;
      case ConnectionQuality.slow:
        return Icons.wifi;
      case ConnectionQuality.offline:
        return Icons.wifi_off;
    }
  }

  Color get statusColor {
    switch (_quality) {
      case ConnectionQuality.fast:
        return const Color(0xFF3FB950);
      case ConnectionQuality.medium:
        return const Color(0xFFD29922);
      case ConnectionQuality.slow:
        return const Color(0xFFF85149);
      case ConnectionQuality.offline:
        return const Color(0xFF8B949E);
    }
  }

  void startMonitoring() {
    _checkNow();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _checkNow());
  }

  void stopMonitoring() {
    _timer?.cancel();
  }

  Future<void> _checkNow() async {
    final stopwatch = Stopwatch()..start();
    try {
      await http.get(
        Uri.parse('${AppConstants.baseUrl}/health'),
      ).timeout(const Duration(seconds: 5));
      stopwatch.stop();
      final latency = stopwatch.elapsedMilliseconds;

      ConnectionQuality newQuality;
      if (latency < 500) {
        newQuality = ConnectionQuality.fast;
      } else if (latency < 2000) {
        newQuality = ConnectionQuality.medium;
      } else {
        newQuality = ConnectionQuality.slow;
      }

      if (newQuality != _quality) {
        _quality = newQuality;
        notifyListeners();
      }
    } catch (_) {
      if (_quality != ConnectionQuality.offline) {
        _quality = ConnectionQuality.offline;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
