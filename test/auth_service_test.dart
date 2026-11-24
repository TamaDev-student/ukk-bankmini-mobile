import 'dart:convert';

import 'package:customer_mobile/services/auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthService login tests', () {
    test('login sukses menyimpan token dan mengembalikan data user nasabah', () async {
      FlutterSecureStorage.setMockInitialValues({});

      final client = MockClient((request) async {
        expect(request.url.path, '/api/login');
        expect(request.headers['Content-Type'], 'application/json');

        final body = jsonDecode(request.body);
        expect(body['username'], '001234');
        expect(body['password'], 'secret123');

        return http.Response(
          jsonEncode({
            'message': 'Login berhasil',
            'token': 'mock_bearer_token_123',
            'user': {
              'id': 10,
              'username': '001234',
              'full_name': 'Ahmad Fauzi',
              'role': 'nasabah',
              'must_change_password': false,
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = AuthService(client: client);
      final user = await service.login(username: '001234', password: 'secret123');

      expect(user['username'], '001234');
      expect(user['role'], 'nasabah');
      expect(await service.getToken(), 'mock_bearer_token_123');
      expect(await service.requiresInitialPasswordChange(), false);
    });

    test('login gagal 401 melempar pesan kesalahan kredensial', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({'message': 'Username atau password salah'}),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = AuthService(client: client);

      expect(
        () => service.login(username: '001234', password: 'wrongpassword'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Username atau password salah'),
          ),
        ),
      );
    });

    test('login gagal 403 melempar pesan akun terblokir', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({'message': 'Akun Anda telah diblokir. Silakan hubungi administrator.'}),
          403,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = AuthService(client: client);

      expect(
        () => service.login(username: '001234', password: 'password'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Akun Anda telah diblokir'),
          ),
        ),
      );
    });

    test('login ditolak jika role bukan nasabah', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'message': 'Login berhasil',
            'token': 'teller_token',
            'user': {
              'id': 1,
              'username': 'teller1',
              'full_name': 'Teller Utama',
              'role': 'teller',
              'must_change_password': false,
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = AuthService(client: client);

      expect(
        () => service.login(username: 'teller1', password: 'password'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('hanya untuk akun nasabah'),
          ),
        ),
      );
    });

    test('respons HTML 405 ditangani secara informatif sebagai endpoint error', () async {
      final client = MockClient((request) async {
        return http.Response(
          '<html><head><title>405 Not Allowed</title></head><body>405 Not Allowed</body></html>',
          405,
          headers: {'content-type': 'text/html; charset=utf-8'},
        );
      });

      final service = AuthService(client: client);

      expect(
        () => service.login(username: '001234', password: 'password'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Endpoint server tidak ditemukan (405)'),
          ),
        ),
      );
    });

    test('respons HTML 500 ditangani secara informatif sebagai server error', () async {
      final client = MockClient((request) async {
        return http.Response(
          '<html><head><title>500 Internal Server Error</title></head></html>',
          500,
          headers: {'content-type': 'text/html; charset=utf-8'},
        );
      });

      final service = AuthService(client: client);

      expect(
        () => service.login(username: '001234', password: 'password'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Server sedang mengalami gangguan (500)'),
          ),
        ),
      );
    });

    test('respons kosong melempar pesan yang sesuai', () async {
      final client = MockClient((request) async {
        return http.Response('', 200);
      });

      final service = AuthService(client: client);

      expect(
        () => service.login(username: '001234', password: 'password'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Server mengembalikan respons kosong'),
          ),
        ),
      );
    });
  });
}

