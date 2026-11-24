
class ApiConfig {
  ApiConfig._();

  static const String _rawBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://tama-dev.my.id/api',
  );

  /// Menghasilkan base URL yang telah dinormalisasi.
  /// Memastikan trailing slash dibersihkan dan path /api selalu ada,
  /// sehingga aman baik saat dijalankan dengan default maupun --dart-define:
  /// - `https://tama-dev.my.id`       -> `https://tama-dev.my.id/api`
  /// - `https://tama-dev.my.id/`      -> `https://tama-dev.my.id/api`
  /// - `https://tama-dev.my.id/api`   -> `https://tama-dev.my.id/api`
  /// - `https://tama-dev.my.id/api/`  -> `https://tama-dev.my.id/api`
  static String get baseUrl {
    var url = _rawBaseUrl.trim();
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    if (!url.endsWith('/api')) {
      url = '$url/api';
    }
    return url;
  }

  static String get loginEndpoint => '$baseUrl/login';
}
