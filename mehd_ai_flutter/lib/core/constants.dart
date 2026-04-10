/// FILE 2 — constants.dart
///
/// Build Debrief:
/// This file stores all hardcoded configurations and application-wide variables. 
/// Centralizing API URLs, symbol lists, and risk parameters means we only have to 
/// update them in one place. If the kill-switch threshold changes from 3% to 4%, 
/// we change it here, and the entire app respects the new rule.

class AppConstants {
  // Network (Use 127.0.0.1:8000 for local Android emulator, or actual Railway URL)
  // For Chrome testing locally we use localhost:8000
  static const String baseUrl = 'http://127.0.0.1:8005'; // Placeholder requested: 'https://mehd-ai-backend.railway.app'
  static const String wsUrl = '$baseUrl/stream';       // Base path for SSE stream endpoints

  // Symbols
  static const List<String> symbols = [
    'EUR/USD',
    'GBP/USD',
    'GBP/JPY',
    'XAU/USD',
    'BTC/USD',
    'ETH/USD',
    'NAS100',
    'US30',
  ];

  // AI Models by Layer (11 Specialized Agents)
  static const List<String> sentimentModels = ['DON', 'PHANTOM', 'ORACLE'];
  static const List<String> strategyModels = ['CAESAR', 'SAGE', 'GUARDIAN'];
  static const List<String> mathModels = ['TITAN', 'ATLAS', 'FORGE', 'THE DON', 'SENTINEL'];

  // Risk Kernel Constants
  static const double maxRiskPercent = 1.0;
  static const double killSwitchPercent = 3.0;
}

/// App-wide button state enum for trade execution flow.
enum ButtonState { locked, readyBuy, readySell, executing, filled, developing, vetoed }
