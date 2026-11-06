import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../home/dashboard_screen.dart';
import '../../services/notification_service.dart';
import 'forgot_password_screen.dart';
import 'first_change_password_screen.dart';
import '../../widgets/bank_mini_logo.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  final AuthService _authService = AuthService();

  bool _obscurePassword = true;
  bool _isLoading = false;

  String? _loginError;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    // Tidak memanggil _authService.dispose() karena http.Client lokal
    // tidak memerlukan cleanup eksplisit di sini. Memanggil dispose()
    // dapat menyebabkan assertion error jika ada async callback yang
    // masih berjalan saat widget sudah tidak ada di tree.
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // Menutup keyboard sebelum proses login.
    FocusScope.of(context).unfocus();

    // Hentikan proses jika validasi form gagal.
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _loginError = null;
    });

    try {
      // Mengirim username dan password ke Laravel API.
      final user = await _authService.login(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (user['must_change_password'] == true) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => const FirstChangePasswordScreen(),
          ),
        );
        return;
      }

      // Inisialisasi notifikasi setelah login berhasil.
      await NotificationService.instance.initialize(
        onOpenTransaction: (transactionId) {
          debugPrint('Transaksi yang dibuka: $transactionId');
        },
        onOpenProfile: () {
          debugPrint('Notifikasi reset PIN: membuka halaman profil.');
        },
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => const DashboardScreen(),
        ),
      );


    } on Exception catch (error) {
      if (!mounted) return;

      // Tampilkan pesan kesalahan dari AuthService.
      setState(() {
        _loginError = error
            .toString()
            .replaceFirst('Exception: ', '');
      });
    } finally {
      // Aktifkan kembali tombol setelah proses selesai.
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 440,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),

                    // Identitas aplikasi.
                    const Center(child: BankMiniLogo()),

                    const SizedBox(height: 28),

                    const Text(
                      'E-Teller',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                        color: AppTheme.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      'Bank Mini Sekolah',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'Masuk untuk melihat informasi rekening '
                      'dan riwayat transaksimu.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: AppTheme.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Kartu form login.
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: const Color(0xFFEAECF0),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Selamat datang!',
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),

                          const SizedBox(height: 6),

                          const Text(
                            'Silakan masuk ke akun nasabah.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Label username NIS.
                          const Text(
                            'Username (NIS)',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Input username menggunakan NIS
                          TextFormField(
                            controller: _usernameController,
                            enabled: !_isLoading,
                            keyboardType: TextInputType.text,
                            textInputAction: TextInputAction.next,
                            autocorrect: false,
                            enableSuggestions: false,
                            decoration: const InputDecoration(
                              hintText: 'Masukkan NIS anda',
                              prefixIcon: Icon(
                                Icons.person_outline_rounded,
                              ),
                            ),
                            validator: (value) {
                              if (value == null ||
                                  value.trim().isEmpty) {
                                return 'NIS wajib diisi.';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

                          // Label password.
                          const Text(
                            'Password',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const ForgotPasswordScreen(),
                                        ),
                                      );
                                    },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                  horizontal: 0,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Lupa Password?',
                                style: TextStyle(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Input password.
                          TextFormField(
                            controller: _passwordController,
                            enabled: !_isLoading,
                            obscureText: _obscurePassword,
                            autocorrect: false,
                            enableSuggestions: false,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) {
                              if (!_isLoading) {
                                _handleLogin();
                              }
                            },
                            decoration: InputDecoration(
                              hintText: 'Masukkan password',
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                              ),
                              suffixIcon: IconButton(
                                tooltip: _obscurePassword
                                    ? 'Tampilkan password'
                                    : 'Sembunyikan password',
                                onPressed: _isLoading
                                    ? null
                                    : () {
                                        setState(() {
                                          _obscurePassword =
                                              !_obscurePassword;
                                        });
                                      },
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Password wajib diisi.';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 8),

                          // Pesan kesalahan login.
                          if (_loginError != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF0F0),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFFFD6D6),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.error_outline_rounded,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _loginError!,
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontSize: 13,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 28),

                          // Tombol login.
                          SizedBox(
                            height: 52,
                            child: FilledButton(
                              onPressed: _isLoading
                                  ? null
                                  : _handleLogin,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor:
                                    AppTheme.primary.withValues(alpha: 0.6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Masuk',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      'Aplikasi layanan informasi rekening '
                      'Bank Mini Sekolah.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: AppTheme.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}