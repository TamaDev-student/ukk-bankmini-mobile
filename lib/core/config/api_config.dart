
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://tama-dev.my.id/api',
  );

  static const String loginEndpoint = '$baseUrl/login';
}
