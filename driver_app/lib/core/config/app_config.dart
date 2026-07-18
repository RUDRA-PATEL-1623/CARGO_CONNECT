class AppConfig {
  const AppConfig._();

  // Android emulator default. For a physical Android device, pass your laptop IP:
  // --dart-define=CARGOCONNECT_API_BASE_URL=http://192.168.1.10:5000/api/v1
  static const String apiBaseUrl = String.fromEnvironment(
    'CARGOCONNECT_API_BASE_URL',
    defaultValue: 'http://localhost:5000/api/v1',
  );

  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 20);
  static const Duration sendTimeout = Duration(seconds: 20);
}
