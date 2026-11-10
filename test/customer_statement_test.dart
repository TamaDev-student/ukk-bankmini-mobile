import 'dart:convert';
import 'dart:typed_data';

import 'package:customer_mobile/services/customer_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CustomerService downloadAccountStatement Tests', () {
    test('berhasil mengunduh byte data PDF saat response 200 application/pdf', () async {
      FlutterSecureStorage.setMockInitialValues({'auth_token': 'dummy_token'});

      final mockPdfBytes = Uint8List.fromList(utf8.encode('%PDF-1.4 mock content'));

      final client = MockClient((request) async {
        expect(request.url.path, '/api/customer/statement/download');
        expect(request.url.queryParameters['start_date'], '2026-11-01');
        expect(request.url.queryParameters['end_date'], '2026-11-10');
        expect(request.headers['Authorization'], 'Bearer dummy_token');

        return http.Response.bytes(
          mockPdfBytes,
          200,
          headers: {'content-type': 'application/pdf'},
        );
      });

      final service = CustomerService(client: client);
      final result = await service.downloadAccountStatement(
        startDate: DateTime(2026, 11, 1),
        endDate: DateTime(2026, 11, 10),
      );

      expect(result, isNotNull);
      expect(result.length, mockPdfBytes.length);
      expect(utf8.decode(result), contains('%PDF-1.4 mock content'));
    });

    test('melempar CustomerApiException 401 saat token kadaluwarsa', () async {
      FlutterSecureStorage.setMockInitialValues({'auth_token': 'expired_token'});

      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({'message': 'Unauthenticated.'}),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = CustomerService(client: client);

      expect(
        () => service.downloadAccountStatement(
          startDate: DateTime(2026, 11, 1),
          endDate: DateTime(2026, 11, 10),
        ),
        throwsA(isA<CustomerApiException>().having((e) => e.statusCode, 'statusCode', 401)),
      );
    });

    test('melempar CustomerApiException saat format bukan PDF', () async {
      FlutterSecureStorage.setMockInitialValues({'auth_token': 'dummy_token'});

      final client = MockClient((request) async {
        return http.Response(
          '<html>Error</html>',
          200,
          headers: {'content-type': 'text/html'},
        );
      });

      final service = CustomerService(client: client);

      expect(
        () => service.downloadAccountStatement(
          startDate: DateTime(2026, 11, 1),
          endDate: DateTime(2026, 11, 10),
        ),
        throwsA(isA<CustomerApiException>().having(
          (e) => e.message,
          'message',
          contains('bukan PDF'),
        )),
      );
    });
  });
}