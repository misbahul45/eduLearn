const String _kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8000/api/v1',
);

const String _kWsBaseUrl = String.fromEnvironment(
  'WS_BASE_URL',
  defaultValue: 'ws://10.0.2.2:8000/ws/v1/chat',
);

class AppConfig {
  AppConfig._();

  static const String apiBaseUrl = _kApiBaseUrl;
  static const String wsBaseUrl = _kWsBaseUrl;
}
