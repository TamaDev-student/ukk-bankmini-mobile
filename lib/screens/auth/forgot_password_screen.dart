import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final AuthService _authService = AuthService();

  // Step:
  // 1. Masukkan NIS
  // 2. Verifikasi OTP
  // 3. Buat password baru
  // 4. Berhasil
  int _currentStep = 1;

  // Form controllers.
  final _nisController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Form keys.
  final _formKeyStep1 = GlobalKey<FormState>();
  final _formKeyStep2 = GlobalKey<FormState>();
  final _formKeyStep3 = GlobalKey<FormState>();

  // Temporary reset token.
  // Tidak disimpan ke SharedPreferences atau SecureStorage.
  String? _resetToken;

  // Loading states.
  bool _isLoading = false;
  bool _isResending = false;

  // Messages.
  String? _errorMessage;
  String? _infoMessage;

  // Password visibility.
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // OTP timers.
  int _otpValiditySeconds = 300;
  int _resendCooldownSeconds = 60;

  Timer? _validityTimer;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _validityTimer?.cancel();
    _cooldownTimer?.cancel();

    _nisController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    _authService.dispose();

    super.dispose();
  }

  // =========================================================================
  // ERROR HANDLING
  // =========================================================================

  String _getErrorMessage(Object error) {
    final message = error.toString().trim();

    return message.replaceFirst(
      RegExp(r'^(Exception|CustomerApiException):\s*'),
      '',
    );
  }

  void _clearError() {
    if (_errorMessage == null) return;

    setState(() {
      _errorMessage = null;
    });
  }

  // =========================================================================
  // TIMER MANAGEMENT
  // =========================================================================

  void _cancelTimers() {
    _validityTimer?.cancel();
    _cooldownTimer?.cancel();

    _validityTimer = null;
    _cooldownTimer = null;
  }

  void _startTimers() {
    _cancelTimers();

    if (!mounted) return;

    setState(() {
      _otpValiditySeconds = 300;
      _resendCooldownSeconds = 60;
    });

    // Timer masa berlaku OTP.
    _validityTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        if (_otpValiditySeconds <= 1) {
          timer.cancel();

          setState(() {
            _otpValiditySeconds = 0;
          });

          return;
        }

        setState(() {
          _otpValiditySeconds--;
        });
      },
    );

    // Timer cooldown pengiriman ulang.
    _cooldownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        if (_resendCooldownSeconds <= 1) {
          timer.cancel();

          setState(() {
            _resendCooldownSeconds = 0;
          });

          return;
        }

        setState(() {
          _resendCooldownSeconds--;
        });
      },
    );
  }

  String _formatTimer(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  // =========================================================================
  // RESET FORM STATE
  // =========================================================================

  void _clearRecoveryData() {
    _cancelTimers();

    _otpController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();

    _resetToken = null;

    _otpValiditySeconds = 300;
    _resendCooldownSeconds = 60;
  }

  void _backToPreviousStep() {
    if (_isLoading || _isResending) return;

    if (_currentStep == 1) {
      Navigator.of(context).pop();
      return;
    }

    if (_currentStep == 2) {
      _cancelTimers();

      setState(() {
        _currentStep = 1;
        _otpController.clear();
        _errorMessage = null;
        _infoMessage = null;
      });

      return;
    }

    // Jika OTP sudah berhasil diverifikasi dan pengguna berada
    // pada tahap pembuatan password, keluar dari proses pemulihan.
    if (_currentStep == 3) {
      _clearRecoveryData();
      Navigator.of(context).pop();
    }
  }

  // =========================================================================
  // STEP 1: REQUEST OTP
  // =========================================================================

  Future<void> _handleRequestOtp() async {
    if (_isLoading) return;

    FocusScope.of(context).unfocus();

    if (!(_formKeyStep1.currentState?.validate() ?? false)) {
      return;
    }

    final studentNumber = _nisController.text.trim();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    try {
      final message = await _authService.requestPasswordResetOtp(
        studentNumber,
      );

      if (!mounted) return;

      setState(() {
        _currentStep = 2;
        _infoMessage = message;
        _resetToken = null;
      });

      _startTimers();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = _getErrorMessage(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // =========================================================================
  // RESEND OTP
  // =========================================================================

  Future<void> _handleResendOtp() async {
    if (_isLoading ||
        _isResending ||
        _resendCooldownSeconds > 0) {
      return;
    }

    final studentNumber = _nisController.text.trim();

    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    try {
      final message = await _authService.requestPasswordResetOtp(
        studentNumber,
      );

      if (!mounted) return;

      setState(() {
        _infoMessage = message;
        _otpController.clear();
      });

      _startTimers();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = _getErrorMessage(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  // =========================================================================
  // STEP 2: VERIFY OTP
  // =========================================================================

  Future<void> _handleVerifyOtp() async {
    if (_isLoading) return;

    FocusScope.of(context).unfocus();

    if (_otpValiditySeconds <= 0) {
      setState(() {
        _errorMessage =
            'Kode OTP telah kedaluwarsa. Silakan minta kode baru.';
      });

      return;
    }

    if (!(_formKeyStep2.currentState?.validate() ?? false)) {
      return;
    }

    final studentNumber = _nisController.text.trim();
    final otp = _otpController.text.trim();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await _authService.verifyPasswordResetOtp(
        studentNumber: studentNumber,
        otp: otp,
      );

      if (!mounted) return;

      if (token.trim().isEmpty) {
        throw Exception(
          'Server tidak memberikan token pemulihan yang valid.',
        );
      }

      _cancelTimers();

      setState(() {
        _resetToken = token;
        _currentStep = 3;
        _infoMessage = null;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = _getErrorMessage(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // =========================================================================
  // STEP 3: RESET PASSWORD
  // =========================================================================

  Future<void> _handleResetPassword() async {
    if (_isLoading) return;

    FocusScope.of(context).unfocus();

    if (!(_formKeyStep3.currentState?.validate() ?? false)) {
      return;
    }

    final token = _resetToken;

    if (token == null || token.trim().isEmpty) {
      setState(() {
        _errorMessage =
            'Sesi pemulihan tidak valid. Silakan ulangi proses.';
      });

      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.resetPassword(
        studentNumber: _nisController.text.trim(),
        resetToken: token,
        password: _passwordController.text,
        passwordConfirmation: _confirmPasswordController.text,
      );

      if (!mounted) return;

      // Hapus data sensitif setelah reset berhasil.
      _resetToken = null;

      _otpController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();

      setState(() {
        _currentStep = 4;
        _errorMessage = null;
        _infoMessage = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = _getErrorMessage(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // =========================================================================
  // SHARED UI COMPONENTS
  // =========================================================================

  Widget _buildErrorMessage() {
    if (_errorMessage == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
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
              _errorMessage!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoMessage() {
    if (_infoMessage == null || _currentStep == 4) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFBFDBFE),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppTheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _infoMessage!,
              style: const TextStyle(
                color: Color(0xFF1E40AF),
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingButton({
    required String label,
    required String loadingLabel,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return SizedBox(
      height: 52,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              AppTheme.primary.withValues(alpha: 0.55),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 21,
                    height: 21,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(loadingLabel),
                ],
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }

  // =========================================================================
  // MAIN BUILD
  // =========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentStep == 4
              ? 'Pemulihan Berhasil'
              : 'Lupa Password',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: _currentStep == 4
            ? null
            : IconButton(
                tooltip: 'Kembali',
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: _isLoading || _isResending
                    ? null
                    : _backToPreviousStep,
              ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 440,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildErrorMessage(),
                  _buildInfoMessage(),

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
                    child: _buildStepContent(),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 1:
        return _buildStep1Nis();

      case 2:
        return _buildStep2Otp();

      case 3:
        return _buildStep3NewPassword();

      case 4:
        return _buildStep4Success();

      default:
        return const SizedBox.shrink();
    }
  }

  // =========================================================================
  // STEP 1: INPUT NIS
  // =========================================================================

  Widget _buildStep1Nis() {
    return Form(
      key: _formKeyStep1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Pemulihan Akun',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Masukkan NIS untuk memulai proses pemulihan password. '
            'Instruksi pemulihan akan dikirim melalui email '
            'apabila akun memenuhi persyaratan.',
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Nomor Induk Siswa (NIS)',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),

          TextFormField(
            controller: _nisController,
            enabled: !_isLoading,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
            textCapitalization: TextCapitalization.none,
            autocorrect: false,
            enableSuggestions: false,
            maxLength: 50,
            decoration: const InputDecoration(
              hintText: 'Masukkan NIS Anda',
              prefixIcon: Icon(
                Icons.badge_outlined,
              ),
              counterText: '',
            ),
            onChanged: (_) => _clearError(),
            onFieldSubmitted: (_) {
              if (!_isLoading) {
                _handleRequestOtp();
              }
            },
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'NIS wajib diisi.';
              }

              if (value.trim().length > 50) {
                return 'NIS maksimal 50 karakter.';
              }

              return null;
            },
          ),

          const SizedBox(height: 24),

          _buildLoadingButton(
            label: 'Kirim Kode OTP',
            loadingLabel: 'Memproses permintaan...',
            isLoading: _isLoading,
            onPressed: _handleRequestOtp,
          ),

          const SizedBox(height: 20),

          // Informasi untuk nasabah tanpa email.
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
              ),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: AppTheme.primary,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Belum mempunyai email pemulihan atau tidak '
                    'dapat mengakses email? Silakan hubungi '
                    'administrator untuk mendapatkan bantuan.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // STEP 2: INPUT OTP
  // =========================================================================

  Widget _buildStep2Otp() {
    return Form(
      key: _formKeyStep2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Text(
                  'Verifikasi OTP',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _otpValiditySeconds > 0
                      ? const Color(0xFFE8EFFF)
                      : const Color(0xFFFFF0F0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _formatTimer(_otpValiditySeconds),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _otpValiditySeconds > 0
                        ? AppTheme.primary
                        : Colors.red,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            'Jika akun memenuhi persyaratan, kode OTP '
            'akan dikirim ke email pemulihan yang terdaftar '
            'untuk NIS ${_nisController.text.trim()}.',
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppTheme.textSecondary,
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'Kode OTP (6 Digit)',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 8),

          // PENTING: OTP controller harus terhubung.
          TextFormField(
            controller: _otpController,
            enabled: !_isLoading && _otpValiditySeconds > 0,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: 12,
              fontFamily: 'monospace',
            ),
            decoration: const InputDecoration(
              hintText: '000000',
              counterText: '',
            ),
            onChanged: (_) => _clearError(),
            onFieldSubmitted: (_) {
              if (!_isLoading && _otpValiditySeconds > 0) {
                _handleVerifyOtp();
              }
            },
            validator: (value) {
              if (value == null ||
                  !RegExp(r'^\d{6}$').hasMatch(value.trim())) {
                return 'Masukkan kode OTP yang terdiri dari 6 digit.';
              }

              return null;
            },
          ),

          if (_otpValiditySeconds == 0) ...[
            const SizedBox(height: 8),
            const Text(
              'Kode OTP telah kedaluwarsa. Silakan minta '
              'kode baru.',
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],

          const SizedBox(height: 24),

          _buildLoadingButton(
            label: 'Verifikasi Kode OTP',
            loadingLabel: 'Memverifikasi...',
            isLoading: _isLoading,
            onPressed: _otpValiditySeconds > 0
                ? _handleVerifyOtp
                : null,
          ),

          const SizedBox(height: 16),

          // Resend OTP.
          Center(
            child: TextButton.icon(
              onPressed: _isLoading ||
                      _isResending ||
                      _resendCooldownSeconds > 0
                  ? null
                  : _handleResendOtp,
              icon: _isResending
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.refresh_rounded,
                      size: 17,
                    ),
              label: Text(
                _resendCooldownSeconds > 0
                    ? 'Kirim Ulang Kode '
                        '(${_resendCooldownSeconds}s)'
                    : 'Kirim Ulang Kode OTP',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFFDE68A),
              ),
            ),
            child: const Text(
              'Penting: Jangan membagikan kode OTP kepada '
              'siapa pun, termasuk petugas bank atau pihak sekolah. '
              'Jika tidak menerima kode, periksa folder Spam '
              'atau hubungi administrator.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF92400E),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // STEP 3: NEW PASSWORD
  // =========================================================================

  Widget _buildStep3NewPassword() {
    return Form(
      key: _formKeyStep3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Buat Password Baru',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Buat password baru untuk akun nasabah '
            '${_nisController.text.trim()}. Gunakan minimal 10 karakter '
            'dengan huruf besar, huruf kecil, dan angka.',
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppTheme.textSecondary,
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'Password Baru',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 8),

          TextFormField(
            controller: _passwordController,
            enabled: !_isLoading,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              hintText: 'Minimal 10 karakter, huruf besar/kecil, dan angka',
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
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            onChanged: (_) => _clearError(),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password baru wajib diisi.';
              }

              if (value.length < 10) {
                return 'Password minimal 10 karakter.';
              }
              if (!RegExp(r'[a-z]').hasMatch(value) ||
                  !RegExp(r'[A-Z]').hasMatch(value) ||
                  !RegExp(r'[0-9]').hasMatch(value)) {
                return 'Gunakan huruf besar, huruf kecil, dan angka.';
              }

              return null;
            },
          ),

          const SizedBox(height: 20),

          const Text(
            'Konfirmasi Password Baru',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 8),

          TextFormField(
            controller: _confirmPasswordController,
            enabled: !_isLoading,
            obscureText: _obscureConfirmPassword,
            textInputAction: TextInputAction.done,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              hintText: 'Ulangi password baru',
              prefixIcon: const Icon(
                Icons.lock_outline_rounded,
              ),
              suffixIcon: IconButton(
                tooltip: _obscureConfirmPassword
                    ? 'Tampilkan password'
                    : 'Sembunyikan password',
                onPressed: _isLoading
                    ? null
                    : () {
                        setState(() {
                          _obscureConfirmPassword =
                              !_obscureConfirmPassword;
                        });
                      },
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            onChanged: (_) => _clearError(),
            onFieldSubmitted: (_) {
              if (!_isLoading) {
                _handleResetPassword();
              }
            },
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

          const SizedBox(height: 28),

          _buildLoadingButton(
            label: 'Simpan Password Baru',
            loadingLabel: 'Menyimpan password...',
            isLoading: _isLoading,
            onPressed: _handleResetPassword,
          ),

          const SizedBox(height: 16),

          const Text(
            'Pastikan password baru berbeda dari password '
            'lama dan tidak mudah ditebak.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // STEP 4: SUCCESS
  // =========================================================================

  Widget _buildStep4Success() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),

        Center(
          child: Container(
            width: 76,
            height: 76,
            decoration: const BoxDecoration(
              color: Color(0xFFD1FAE5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF059669),
              size: 48,
            ),
          ),
        ),

        const SizedBox(height: 20),

        const Text(
          'Password Berhasil Diubah!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),

        const SizedBox(height: 10),

        Text(
          'Password akun nasabah ${_nisController.text.trim()} '
          'telah berhasil diperbarui. '
          'Silakan login kembali menggunakan password baru.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            height: 1.6,
            color: AppTheme.textSecondary,
          ),
        ),

        const SizedBox(height: 32),

        SizedBox(
          height: 52,
          child: FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Kembali ke Halaman Login',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}