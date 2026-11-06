import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../home/dashboard_screen.dart';

class FirstChangePasswordScreen extends StatefulWidget {
  const FirstChangePasswordScreen({super.key});

  @override
  State<FirstChangePasswordScreen> createState() =>
      _FirstChangePasswordScreenState();
}

class _FirstChangePasswordScreenState extends State<FirstChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmationController.dispose();
    _authService.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value) {
    if (value == null || value.length < 10) {
      return 'Gunakan minimal 10 karakter.';
    }
    if (!RegExp(r'[a-z]').hasMatch(value) ||
        !RegExp(r'[A-Z]').hasMatch(value) ||
        !RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password harus memuat huruf besar, huruf kecil, dan angka.';
    }
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.changeInitialPassword(
        password: _passwordController.text,
        passwordConfirmation: _confirmationController.text,
      );
      if (!mounted) return;

      try {
        await NotificationService.instance.initialize(
          onOpenTransaction: (transactionId) {
            debugPrint('Transaksi yang dibuka: $transactionId');
          },
          onOpenProfile: () {
            debugPrint('Notifikasi reset PIN: membuka halaman profil.');
          },
        );
      } on Exception catch (error) {
        debugPrint('Inisialisasi notifikasi gagal: ${error.runtimeType}');
      }
      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => const DashboardScreen(),
        ),
        (_) => false,
      );
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Ganti Password'),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.lock_reset_rounded,
                        color: AppTheme.primary,
                        size: 52,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Buat password permanen',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Untuk melindungi akun, password sementara harus diganti sebelum menggunakan aplikasi.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 28),
                      TextFormField(
                        controller: _passwordController,
                        enabled: !_isLoading,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Password baru',
                          suffixIcon: IconButton(
                            onPressed: _isLoading
                                ? null
                                : () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: _validatePassword,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmationController,
                        enabled: !_isLoading,
                        obscureText: _obscureConfirmation,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: 'Konfirmasi password baru',
                          suffixIcon: IconButton(
                            onPressed: _isLoading
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
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Konfirmasi password wajib diisi.';
                          }
                          if (value != _passwordController.text) {
                            return 'Konfirmasi password tidak cocok.';
                          }
                          return null;
                        },
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _isLoading ? null : _submit,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Simpan Password'),
                      ),
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
