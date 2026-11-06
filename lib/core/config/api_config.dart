class ApiConfig {
  ApiConfig._();

  // Untuk Android Emulator.
  static const String baseUrl = 'http://192.168.100.31  :8000/api';

  static const String loginEndpoint = '$baseUrl/login';
}