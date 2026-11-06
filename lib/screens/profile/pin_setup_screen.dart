import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../services/customer_service.dart';

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key, required this.customerService});

  final CustomerService customerService;

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pinController = TextEditingController();
  final _confirmationController = TextEditingController();

  var _obscurePin = true;
  var _obscureConfirmation = true;
  var _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await widget.customerService.createPin(
        pin: _pinController.text,
        pinConfirmation: _confirmationController.text,
      );

      if (mounted) Navigator.of(context).pop(true);
    } on CustomerApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _isSubmitting = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Terjadi kesalahan. Silakan coba kembali.';
        _isSubmitting = false;
      });
    }
  }

  String? _validatePin(String? value) {
    if (value == null || value.isEmpty) return 'PIN wajib diisi.';
    if (!RegExp(r'^\d{6}$').hasMatch(value)) {
      return 'PIN harus terdiri dari 6 digit angka.';
    }
    return null;
  }

  String? _validateConfirmation(String? value) {
    if (value == null || value.isEmpty) {
      return 'Konfirmasi PIN wajib diisi.';
    }
    if (!RegExp(r'^\d{6}$').hasMatch(value)) {
      return 'PIN harus terdiri dari 6 digit angka.';
    }
    if (value != _pinController.text) return 'Konfirmasi PIN tidak cocok.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSubmitting,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(title: const Text('Buat PIN Transaksi')),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Icon(
                            Icons.lock_person_rounded,
                            color: AppTheme.primary,
                            size: 44,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Buat PIN Transaksi',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Buat PIN 6 digit yang akan digunakan untuk mengonfirmasi transaksi penarikan.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _pinController,
                            obscureText: _obscurePin,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(6),
                            ],
                            enabled: !_isSubmitting,
                            decoration: InputDecoration(
                              labelText: 'PIN Baru',
                              hintText: '6 digit angka',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                tooltip: _obscurePin
                                    ? 'Tampilkan PIN'
                                    : 'Sembunyikan PIN',
                                onPressed: _isSubmitting
                                    ? null
                                    : () => setState(
                                        () => _obscurePin = !_obscurePin,
                                      ),
                                icon: Icon(
                                  _obscurePin
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            validator: _validatePin,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _confirmationController,
                            obscureText: _obscureConfirmation,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(6),
                            ],
                            enabled: !_isSubmitting,
                            decoration: InputDecoration(
                              labelText: 'Konfirmasi PIN',
                              hintText: 'Ulangi PIN 6 digit',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                tooltip: _obscureConfirmation
                                    ? 'Tampilkan PIN'
                                    : 'Sembunyikan PIN',
                                onPressed: _isSubmitting
                                    ? null
                                    : () => setState(
                                        () => _obscureConfirmation =
                                            !_obscureConfirmation,
                                      ),
                                icon: Icon(
                                  _obscureConfirmation
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            validator: _validateConfirmation,
                          ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Color(0xFFEF4444),
                                fontSize: 13,
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: _isSubmitting ? null : _submit,
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Simpan PIN'),
                          ),
                        ],
                      ),
                    ),
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
