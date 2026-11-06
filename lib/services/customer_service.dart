import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../core/config/api_config.dart';
import '../models/customer_account.dart';
import '../models/customer_transaction.dart';

class CustomerApiException implements Exception {
  final String message;
  final int statusCode;
  final int? remainingAttempts;
  final bool isBlocked;

  CustomerApiException({
    required this.message,
    required this.statusCode,
    this.remainingAttempts,
    this.isBlocked = false,
  });

  @override
  String toString() => message;
}

class CustomerService {
  CustomerService({http.Client? client, FlutterSecureStorage? storage})
    : _client = client ?? http.Client(),
      _storage = storage ?? const FlutterSecureStorage();

  final http.Client _client;
  final FlutterSecureStorage _storage;

  Future<Map<String, String>> _headers() async {
    final token = await _storage.read(key: 'auth_token');

    if (token == null || token.isEmpty) {
      throw CustomerApiException(
        message: 'Sesi login tidak ditemukan. Silakan login kembali.',
        statusCode: 401,
      );
    }

    return {'Accept': 'application/json', 'Authorization': 'Bearer $token'};
  }

  Future<Map<String, dynamic>> _getJson(String path) async {
    final response = await _client
        .get(Uri.parse('${ApiConfig.baseUrl}$path'), headers: await _headers())
        .timeout(const Duration(seconds: 15));

    return _decodeResponse(response);
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    dynamic decoded;

    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw CustomerApiException(
        message: 'Server mengirim respons yang tidak valid.',
        statusCode: response.statusCode,
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw CustomerApiException(
        message: 'Format respons server tidak sesuai.',
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode == 401) {
      throw CustomerApiException(
        message: 'Sesi login berakhir. Silakan login kembali.',
        statusCode: 401,
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message =
          decoded['message']?.toString() ??
          'Permintaan gagal (${response.statusCode}).';
      final isBlocked =
          decoded['is_blocked'] == true || response.statusCode == 403;
      final remaining = decoded['remaining_attempts'] is int
          ? decoded['remaining_attempts'] as int
          : null;

      throw CustomerApiException(
        message: message,
        statusCode: response.statusCode,
        remainingAttempts: remaining,
        isBlocked: isBlocked,
      );
    }

    return decoded;
  }

  Future<CustomerAccount> getAccount() async {
    final response = await _getJson('/customer/account');
    final data = response['data'];

    if (data is! Map<String, dynamic>) {
      throw CustomerApiException(
        message: 'Data rekening dari server tidak valid.',
        statusCode: 200,
      );
    }

    return CustomerAccount.fromJson(data);
  }

  Future<Map<String, dynamic>> createPin({
    required String pin,
    required String pinConfirmation,
  }) async {
    final response = await _client
        .post(
          Uri.parse('${ApiConfig.baseUrl}/customer/pin'),
          headers: {...await _headers(), 'Content-Type': 'application/json'},
          body: jsonEncode({'pin': pin, 'pin_confirmation': pinConfirmation}),
        )
        .timeout(const Duration(seconds: 15));

    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> requestRecoveryEmail({
    required String email,
    required String password,
  }) async {
    final response = await _client
        .post(
          Uri.parse('${ApiConfig.baseUrl}/customer/recovery-email/request'),
          headers: {...await _headers(), 'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password}),
        )
        .timeout(const Duration(seconds: 15));

    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> verifyRecoveryEmail({
    required String otp,
    required int challengeId,
  }) async {
    final response = await _client
        .post(
          Uri.parse('${ApiConfig.baseUrl}/customer/recovery-email/verify'),
          headers: {...await _headers(), 'Content-Type': 'application/json'},
          body: jsonEncode({'otp': otp, 'challenge_id': challengeId}),
        )
        .timeout(const Duration(seconds: 15));

    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> requestCurrentEmailVerification() async {
    final response = await _client
        .post(
          Uri.parse(
            '${ApiConfig.baseUrl}/customer/recovery-email/verify-request',
          ),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 15));

    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> requestPinResetOtp() async {
    final response = await _client
        .post(
          Uri.parse('${ApiConfig.baseUrl}/customer/pin-reset/otp'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 15));

    return _decodeResponse(response);
  }

  Future<String> verifyPinResetOtp({required String otp}) async {
    final response = await _client
        .post(
          Uri.parse('${ApiConfig.baseUrl}/customer/pin-reset/verify'),
          headers: {...await _headers(), 'Content-Type': 'application/json'},
          body: jsonEncode({'otp': otp}),
        )
        .timeout(const Duration(seconds: 15));

    final decoded = _decodeResponse(response);
    final data = decoded['data'];
    final resetToken = data is Map<String, dynamic>
        ? data['reset_token']?.toString()
        : null;
    if (resetToken == null || resetToken.isEmpty) {
      throw CustomerApiException(
        message: 'Otorisasi reset dari server tidak valid.',
        statusCode: response.statusCode,
      );
    }

    return resetToken;
  }

  Future<Map<String, dynamic>> completePinReset({
    required String resetToken,
    required String pin,
    required String pinConfirmation,
  }) async {
    final response = await _client
        .post(
          Uri.parse('${ApiConfig.baseUrl}/customer/pin-reset/complete'),
          headers: {...await _headers(), 'Content-Type': 'application/json'},
          body: jsonEncode({
            'reset_token': resetToken,
            'pin': pin,
            'pin_confirmation': pinConfirmation,
          }),
        )
        .timeout(const Duration(seconds: 15));

    return _decodeResponse(response);
  }

  Future<void> registerFcmToken(String token) async {
    final trimmed = token.trim();
    if (trimmed.isEmpty) return;

    try {
      final headers = await _headers();
      final response = await _client
          .post(
            Uri.parse('${ApiConfig.baseUrl}/customer/fcm-token'),
            headers: {...headers, 'Content-Type': 'application/json'},
            body: jsonEncode({'token': trimmed, 'device_type': 'android'}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('[FCM] Registrasi FID berhasil.');
        return;
      }

      if (response.statusCode == 401) {
        debugPrint('[FCM] Registrasi gagal. HTTP 401.');
        return;
      }

      if (response.statusCode == 403) {
        debugPrint('[FCM] Registrasi gagal. HTTP 403.');
        return;
      }

      if (response.statusCode == 422) {
        debugPrint('[FCM] Registrasi gagal. HTTP 422.');
        return;
      }

      debugPrint('[FCM] Registrasi gagal. HTTP ${response.statusCode}.');
    } on TimeoutException {
      debugPrint('[FCM] Backend tidak dapat dijangkau.');
    } on CustomerApiException catch (error) {
      if (error.statusCode == 401) {
        debugPrint('[FCM] Registrasi gagal. HTTP 401.');
      } else {
        debugPrint('[FCM] Registrasi gagal. HTTP ${error.statusCode}.');
      }
    } catch (_) {
      debugPrint('[FCM] Backend tidak dapat dijangkau.');
    }
  }

  Future<void> removeFcmToken([String? token]) async {
    try {
      final headers = await _headers();
      final response = await _client
          .delete(
            Uri.parse('${ApiConfig.baseUrl}/customer/fcm-token'),
            headers: {...headers, 'Content-Type': 'application/json'},
            body: jsonEncode({
              if (token != null && token.isNotEmpty) 'token': token,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        debugPrint('[FCM] Token perangkat berhasil dihapus dari backend.');
      }
    } catch (_) {
      // Safe no-op saat logout jika jaringan terputus
    }
  }

  Future<List<CustomerTransaction>> getTransactions() async {
    final response = await _getJson('/customer/transactions');
    final data = response['data'];

    if (data is! List) {
      throw CustomerApiException(
        message: 'Data riwayat transaksi dari server tidak valid.',
        statusCode: 200,
      );
    }

    return data.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Format transaksi tidak valid.');
      }

      return CustomerTransaction.fromJson(item);
    }).toList();
  }

  Future<CustomerTransaction> getTransactionDetail(int id) async {
    final response = await _getJson('/customer/transactions/$id');
    final data = response['data'];

    if (data is! Map<String, dynamic>) {
      throw CustomerApiException(
        message: 'Detail transaksi dari server tidak valid.',
        statusCode: 200,
      );
    }

    return CustomerTransaction.fromJson(data);
  }

  Future<CustomerTransaction> cancelTransaction(int id) async {
    final response = await _client
        .post(
          Uri.parse('${ApiConfig.baseUrl}/customer/transactions/$id/cancel'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 15));

    final decoded = _decodeResponse(response);
    final data = decoded['data'];

    if (data is! Map<String, dynamic>) {
      throw CustomerApiException(
        message: 'Data transaksi dari server tidak valid.',
        statusCode: response.statusCode,
      );
    }

    return CustomerTransaction.fromJson(data);
  }

  Future<Map<String, dynamic>> confirmTransaction({
    required int transactionId,
    required String pin,
  }) async {
    final response = await _client
        .post(
          Uri.parse(
            '${ApiConfig.baseUrl}/customer/transactions/$transactionId/confirm',
          ),
          headers: {...await _headers(), 'Content-Type': 'application/json'},
          body: jsonEncode({'pin': pin}),
        )
        .timeout(const Duration(seconds: 15));

    return _decodeResponse(response);
  }

  Future<void> logout([String? fid]) async {
    try {
      await removeFcmToken(fid);
      final response = await _client
          .post(
            Uri.parse('${ApiConfig.baseUrl}/logout'),
            headers: await _headers(),
          )
          .timeout(const Duration(seconds: 15));

      _decodeResponse(response);
    } finally {
      // Hapus token lokal meskipun permintaan logout gagal.
      await _storage.delete(key: 'auth_token');
    }
  }

  void dispose() {
    _client.close();
  }
}
