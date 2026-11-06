import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../services/customer_service.dart';

class PinRecoveryScreen extends StatefulWidget {
  const PinRecoveryScreen({
    super.key,
    required this.customerService,
    required this.maskedEmail,
    required this.pinLocked,
  });

  final CustomerService customerService;
  final String maskedEmail;
  final bool pinLocked;

  @override
  State<PinRecoveryScreen> createState() => _PinRecoveryScreenState();
}

class _PinRecoveryScreenState extends State<PinRecoveryScreen> {
  final _otpController = TextEditingController();
  final _pinController = TextEditingController();
  final _pinConfirmationController = TextEditingController();
  var _step = 0;
  var _busy = false;
  String? _resetToken;

  @override
  void dispose() {
    _otpController.dispose();
    _pinController.dispose();
    _pinConfirmationController.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    await _run(() async {
      await widget.customerService.requestPinResetOtp();
      if (mounted) setState(() => _step = 1);
    });
  }

  Future<void> _verifyOtp() async {
    if (!RegExp(r'^\d{6}$').hasMatch(_otpController.text)) {
      _showMessage('Masukkan OTP yang terdiri dari 6 digit.');
      return;
    }

    await _run(() async {
      _resetToken = await widget.customerService.verifyPinResetOtp(
        otp: _otpController.text,
      );
      if (mounted) setState(() => _step = 2);
    });
  }

  Future<void> _savePin() async {
    final pin = _pinController.text;
    if (!RegExp(r'^\d{6}$').hasMatch(pin)) {
      _showMessage('PIN baru harus terdiri dari 6 digit.');
      return;
    }
    if (pin != _pinConfirmationController.text) {
      _showMessage('Konfirmasi PIN tidak sama.');
      return;
    }

    final token = _resetToken;
    if (token == null) {
      _showMessage('Sesi reset tidak ditemukan. Minta OTP baru.');
      return;
    }

    await _run(() async {
      await widget.customerService.completePinReset(
        resetToken: token,
        pin: pin,
        pinConfirmation: _pinConfirmationController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PIN transaksi berhasil diperbarui.'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      Navigator.of(context).pop(true);
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (error) {
      _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFEF4444),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Keamanan PIN Transaksi')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.lock_reset_rounded,
                        size: 44,
                        color: AppTheme.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _step == 0
                            ? 'Lupa PIN Transaksi'
                            : _step == 1
                            ? 'Verifikasi OTP'
                            : 'Buat PIN Baru',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _step == 0
                            ? 'Kode verifikasi akan dikirim ke ${widget.maskedEmail}.'
                            : _step == 1
                            ? 'Masukkan kode 6 digit yang dikirim ke ${widget.maskedEmail}.'
                            : 'Buat PIN baru 6 digit dan konfirmasikan.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      if (_step == 0 && widget.pinLocked) ...[
                        const SizedBox(height: 12),
                        const Text(
                          'PIN sedang terkunci. Reset PIN hanya akan membuka kunci setelah PIN baru berhasil disimpan.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFFB45309)),
                        ),
                      ],
                      const SizedBox(height: 24),
                      if (_step == 0)
                        FilledButton(
                          onPressed: _busy ? null : _requestOtp,
                          child: _busy
                              ? const CircularProgressIndicator()
                              : const Text('Kirim OTP'),
                        )
                      else if (_step == 1) ...[
                        TextField(
                          controller: _otpController,
                          autofocus: true,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Kode OTP',
                            prefixIcon: Icon(Icons.password_rounded),
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _busy ? null : _verifyOtp,
                          child: _busy
                              ? const CircularProgressIndicator()
                              : const Text('Verifikasi OTP'),
                        ),
                        TextButton(
                          onPressed: _busy ? null : _requestOtp,
                          child: const Text('Kirim ulang OTP'),
                        ),
                      ] else ...[
                        TextField(
                          controller: _pinController,
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'PIN baru',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _pinConfirmationController,
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Konfirmasi PIN baru',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _busy ? null : _savePin,
                          child: _busy
                              ? const CircularProgressIndicator()
                              : const Text('Simpan PIN Baru'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
