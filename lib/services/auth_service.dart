import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../core/config/api_config.dart';
import 'customer_service.dart';

class AuthService {
  static const _tokenKey = 'auth_token';
  static const _mustChangePasswordKey = 'must_change_password';

  AuthService({
    http.Client? client,
    FlutterSecureStorage? storage,
  })  : _client = client ?? http.Client(),
        _storage = storage ?? const FlutterSecureStorage();

  final http.Client _client;
  final FlutterSecureStorage _storage;

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final uri = Uri.parse(ApiConfig.loginEndpoint);

    final response = await _client
        .post(
          uri,
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'username': username,
            'password': password,
          }),
        )
        .timeout(const Duration(seconds: 15));

    final dynamic decodedBody;

    try {
      decodedBody = jsonDecode(response.body);
    } on FormatException {
      throw Exception('Server mengirim respons yang tidak valid.');
    }

    if (decodedBody is! Map<String, dynamic>) {
      throw Exception('Format respons server tidak sesuai.');
    }

    if (response.statusCode == 401) {
      throw Exception('Username atau password salah.');
    }

    if (response.statusCode == 403) {
      throw Exception(
        decodedBody['message']?.toString() ??
            'Akun tidak diizinkan untuk masuk.',
      );
    }

    if (response.statusCode != 200) {
      throw Exception(
        decodedBody['message']?.toString() ??
            'Login gagal. Periksa koneksi dan server.',
      );
    }

    final token = decodedBody['token'];
    final user = decodedBody['user'];

    if (token is! String ||
        token.isEmpty ||
        user is! Map<String, dynamic>) {
      throw Exception('Respons login tidak memiliki token atau data user.');
    }

    if (user['role'] != 'nasabah') {
      throw Exception('Aplikasi ini hanya untuk akun nasabah.');
    }

    await _storage.write(
      key: _mustChangePasswordKey,
      value: user['must_change_password'] == true ? 'true' : 'false',
    );
    await _storage.write(
      key: _tokenKey,
      value: token,
    );

    return user;
  }

  Future<String?> getToken() {
    return _storage.read(key: _tokenKey);
  }

  Future<bool> requiresInitialPasswordChange() async {
    return await _storage.read(key: _mustChangePasswordKey) == 'true';
  }

  Future<void> clearStoredSession() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _mustChangePasswordKey);
  }

  Future<void> changeInitialPassword({
    required String password,
    required String passwordConfirmation,
  }) async {
    final token = await getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Sesi login tidak ditemukan. Silakan login kembali.');
    }

    final response = await _client
        .post(
          Uri.parse('${ApiConfig.baseUrl}/customer/password/first-change'),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'password': password,
            'password_confirmation': passwordConfirmation,
          }),
        )
        .timeout(const Duration(seconds: 15));

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw Exception('Server mengirim respons yang tidak valid.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map<String, dynamic>
          ? decoded['message']?.toString()
          : null;
      throw Exception(message ?? 'Password gagal diperbarui.');
    }

    await _storage.write(key: _mustChangePasswordKey, value: 'false');
  }

  Future<String> requestPasswordResetOtp(String studentNumber) async {
    final response = await _client
        .post(
          Uri.parse('${ApiConfig.baseUrl}/customer/forgot-password'),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'student_number': studentNumber,
          }),
        )
        .timeout(const Duration(seconds: 15));

    final dynamic decodedBody;
    try {
      decodedBody = jsonDecode(response.body);
    } catch (_) {
      throw Exception('Server mengirim respons yang tidak valid.');
    }

    if (response.statusCode == 429) {
      throw Exception(
        decodedBody is Map
            ? decodedBody['message']?.toString() ?? 'Terlalu banyak permintaan.'
            : 'Terlalu banyak permintaan. Silakan tunggu beberapa saat.',
      );
    }

    if (response.statusCode != 200) {
      throw Exception(
        decodedBody is Map
            ? decodedBody['message']?.toString() ?? 'Gagal meminta kode OTP.'
            : 'Gagal meminta kode OTP.',
      );
    }

    return (decodedBody is Map && decodedBody['message'] != null)
        ? decodedBody['message'].toString()
        : 'Jika akun terdaftar dan memiliki email pemulihan, kode OTP telah dikirimkan.';
  }

  Future<String> verifyPasswordResetOtp({
    required String studentNumber,
    required String otp,
  }) async {
    final response = await _client
        .post(
          Uri.parse('${ApiConfig.baseUrl}/customer/verify-reset-otp'),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'student_number': studentNumber,
            'otp': otp,
          }),
        )
        .timeout(const Duration(seconds: 15));

    final dynamic decodedBody;
    try {
      decodedBody = jsonDecode(response.body);
    } catch (_) {
      throw Exception('Server mengirim respons yang tidak valid.');
    }

    if (response.statusCode != 200) {
      final msg = decodedBody is Map
          ? decodedBody['message']?.toString() ?? 'Kode OTP tidak valid.'
          : 'Kode OTP tidak valid.';
      throw Exception(msg);
    }

    final token = decodedBody is Map ? decodedBody['reset_token'] : null;
    if (token is! String || token.isEmpty) {
      throw Exception('Sesi token pemulihan tidak valid dari server.');
    }

    return token;
  }

  Future<String> resetPassword({
    required String studentNumber,
    required String resetToken,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await _client
        .post(
          Uri.parse('${ApiConfig.baseUrl}/customer/reset-password'),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'student_number': studentNumber,
            'reset_token': resetToken,
            'password': password,
            'password_confirmation': passwordConfirmation,
          }),
        )
        .timeout(const Duration(seconds: 15));

    final dynamic decodedBody;
    try {
      decodedBody = jsonDecode(response.body);
    } catch (_) {
      throw Exception('Server mengirim respons yang tidak valid.');
    }

    if (response.statusCode != 200) {
      final msg = decodedBody is Map
          ? decodedBody['message']?.toString() ?? 'Gagal memperbarui password.'
          : 'Gagal memperbarui password.';
      throw Exception(msg);
    }

    return (decodedBody is Map && decodedBody['message'] != null)
        ? decodedBody['message'].toString()
        : 'Password berhasil diperbarui. Silakan login menggunakan password baru.';
  }

  Future<void> logout([String? fid]) async {
    final token = await getToken();

    if (token != null) {
      try {
        await CustomerService().removeFcmToken(fid);
        await _client
            .post(
              Uri.parse('${ApiConfig.baseUrl}/logout'),
              headers: {
                'Accept': 'application/json',
                'Authorization': 'Bearer $token',
              },
            )
            .timeout(const Duration(seconds: 15));
      } finally {
        await clearStoredSession();
      }
    } else {
      await _storage.delete(key: _mustChangePasswordKey);
    }
  }

  void dispose() {
    _client.close();
  }
}
