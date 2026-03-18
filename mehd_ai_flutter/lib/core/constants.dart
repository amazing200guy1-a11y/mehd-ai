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
  static const String baseUrl = 'http://127.0.0.1:8000'; // Placeholder requested: 'https://mehd-ai-backend.railway.app'
  static const String wsUrl = '$baseUrl/stream';       // Base path for SSE stream endpoints

  // Symbols
  static const List<String> symbols = [
    'EUR/USD',
    'EUR/USD',
    'GBP/JPY',
    'XAU/USD',
    'BTC/USD',
    'ETH/USD',
    'PARADOX/USD', // Testing Sentinel Mock
    'NAS100',
    'US30',
    'BTC/USD'
  ];

  // AI Models by Layer
  static const List<String> sentimentModels = ['grok', 'perplexity', 'gemini'];
  static const List<String> strategyModels = ['claude', 'gpt-4', 'llama'];
  static const List<String> mathModels = ['deepseek', 'openai-o3', 'codestral'];

  // Risk Kernel Constants
  static const double maxRiskPercent = 1.0;
  static const double killSwitchPercent = 3.0;
}
