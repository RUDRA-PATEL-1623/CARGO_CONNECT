class AppConfig {
  const AppConfig._();

  // Flutter Web/Admin local default. Override with:
  // --dart-define=CARGOCONNECT_API_BASE_URL=http://localhost:5000/api/v1
  static const String apiBaseUrl = String.fromEnvironment(
    'CARGOCONNECT_API_BASE_URL',
    defaultValue: 'http://localhost:5000/api/v1',
  );

  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 20);
  static const Duration sendTimeout = Duration(seconds: 20);
}
