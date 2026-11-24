import 'package:customer_mobile/core/config/api_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApiConfig Tests', () {
    test('baseUrl default selalu memiliki format dengan akhiran /api tanpa trailing slash', () {
      expect(ApiConfig.baseUrl.endsWith('/api'), isTrue);
      expect(ApiConfig.baseUrl.endsWith('/'), isFalse);
    });

    test('loginEndpoint selalu mengarah ke {baseUrl}/login', () {
      expect(ApiConfig.loginEndpoint, '${ApiConfig.baseUrl}/login');
      expect(ApiConfig.loginEndpoint, contains('/api/login'));
      expect(ApiConfig.loginEndpoint, isNot(contains('//login')));
    });
  });
}

