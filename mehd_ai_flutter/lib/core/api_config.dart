class ApiConfig {
  /// Set to false when API keys are added to activate real data flow.
  /// This single constant governs the entire application's data source.
  static const bool demoMode = bool.fromEnvironment('DEMO_MODE', defaultValue: true);

  /// The backend API root. Defaults to localhost for development.
  static const String backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://localhost:8000',
  );

  /// The WebSocket/SSE price stream endpoint.
  static const String streamUrl = '$backendUrl/stream';
}
