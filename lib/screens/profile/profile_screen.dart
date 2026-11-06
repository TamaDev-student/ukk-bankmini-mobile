import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../models/customer_account.dart';
import '../../services/customer_service.dart';
import '../../services/notification_service.dart';
import '../auth/login_screen.dart';
import '../help/help_center_screen.dart';
import '../home/dashboard_screen.dart';
import '../transactions/mutasi_screen.dart';
import '../transactions/persetujuan_screen.dart';
import 'pin_recovery_screen.dart';
import 'pin_setup_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.onLoggedOut, this.customerService});

  /// Callback untuk mengarahkan pengguna ke halaman Login.
  final VoidCallback? onLoggedOut;
  final CustomerService? customerService;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final CustomerService _customerService;

  late Future<CustomerAccount> _accountFuture;

  bool _isLoggingOut = false;

  void _onNavigationTap(int index) {
    if (index == 3) return;

    if (index == 0) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => const DashboardScreen()),
        );
      }
      return;
    }

    final Widget destination = index == 1
        ? const MutasiScreen()
        : const PersetujuanScreen();
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute<void>(builder: (_) => destination));
  }

  Widget _buildBottomNavigation() {
    const destinations = [
      (label: 'Beranda', icon: Icons.home_outlined),
      (label: 'Mutasi', icon: Icons.receipt_long_rounded),
      (label: 'Persetujuan', icon: Icons.fact_check_outlined),
      (label: 'Profil', icon: Icons.person_rounded),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE2E7FF))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(destinations.length, (index) {
              final destination = destinations[index];
              final isSelected = index == 3;
              final color = isSelected
                  ? AppTheme.primary
                  : AppTheme.textSecondary;

              return Expanded(
                child: InkWell(
                  onTap: () => _onNavigationTap(index),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(destination.icon, size: 22, color: color),
                      const SizedBox(height: 4),
                      Text(
                        destination.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _customerService = widget.customerService ?? CustomerService();
    _accountFuture = _customerService.getAccount();
  }

  @override
  void dispose() {
    // Tidak memanggil _customerService.dispose() karena dialog-
    // dialog (CreatePin, RecoveryEmail, VerifyOtp) menerima
    // referensi ke _customerService yang sama dan mungkin masih
    // aktif saat ProfileScreen di-pop dari stack. Memanggil
    // dispose() pada http.Client yang masih digunakan dapat
    // menyebabkan assertion _dependents.isEmpty di Flutter framework.
    super.dispose();
  }

  void _reloadProfile() {
    setState(() {
      _accountFuture = _customerService.getAccount();
    });
  }

  String _getInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'N';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  String _formatRupiah(int amount) {
    final digits = amount.toString();
    final buffer = StringBuffer();

    for (var i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);
      final remaining = digits.length - i - 1;
      if (remaining > 0 && remaining % 3 == 0) {
        buffer.write('.');
      }
    }

    return 'Rp$buffer';
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return 'Aktif';
      case 'blocked':
        return 'Diblokir';
      case 'inactive':
        return 'Nonaktif';
      default:
        return status.isEmpty ? 'Tidak Diketahui' : status;
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return const Color(0xFF10B981);
      case 'blocked':
        return const Color(0xFFEF4444);
      case 'inactive':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF6B7280);
    }
  }

  Color _statusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return const Color(0xFFECFDF5);
      case 'blocked':
        return const Color(0xFFFEF2F2);
      case 'inactive':
        return const Color(0xFFFFFBEB);
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  Future<void> _copyToClipboard(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text('$label berhasil disalin ke clipboard.'),
          ],
        ),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _openPinSetup() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => PinSetupScreen(customerService: _customerService),
      ),
    );

    if (result == true && mounted) {
      _reloadProfile();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PIN transaksi berhasil dibuat dan aktif.'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    }
  }

  Future<void> _verifyCurrentRecoveryEmail(String maskedEmail) async {
    try {
      final response = await _customerService.requestCurrentEmailVerification();
      final data = response['data'];
      final challengeId = data is Map<String, dynamic>
          ? int.tryParse(data['challenge_id']?.toString() ?? '')
          : null;

      if (challengeId == null) {
        throw CustomerApiException(
          message: 'Server tidak mengembalikan identitas permintaan OTP.',
          statusCode: 200,
        );
      }

      if (mounted) {
        await _showVerifyRecoveryEmailOtpDialog(
          maskedEmail,
          challengeId: challengeId,
        );
      }
    } on CustomerApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  Future<void> _openPinRecovery(CustomerAccount account) async {
    if (!account.recoveryEmailVerified || account.recoveryEmail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verifikasi email pribadi sebelum mengatur ulang PIN.'),
        ),
      );
      return;
    }

    final reset = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => PinRecoveryScreen(
          customerService: _customerService,
          maskedEmail: account.recoveryEmail!,
          pinLocked: account.pinLocked,
        ),
      ),
    );
    if (reset == true && mounted) _reloadProfile();
  }

  Future<void> _showRequestRecoveryEmailDialog(String? currentEmail) async {
    final request = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _RequestRecoveryEmailDialog(
        currentEmail: currentEmail,
        customerService: _customerService,
      ),
    );

    if (request != null && mounted) {
      final targetEmail = request['email'];
      final challengeId = request['challenge_id'];
      if (targetEmail is String && challengeId is int) {
        await _showVerifyRecoveryEmailOtpDialog(
          targetEmail,
          challengeId: challengeId,
        );
      }
    }
  }

  Future<void> _showVerifyRecoveryEmailOtpDialog(
    String newEmail, {
    required int challengeId,
  }) async {
    final verified = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _VerifyRecoveryEmailOtpDialog(
        newEmail: newEmail,
        challengeId: challengeId,
        customerService: _customerService,
      ),
    );

    if (verified == true && mounted) {
      _reloadProfile();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email pemulihan berhasil diverifikasi dan disimpan.'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    }
  }

  Future<void> _confirmLogout() async {
    if (_isLoggingOut) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Konfirmasi Logout'),
          content: const Text(
            'Apakah kamu yakin ingin keluar dari akun nasabah ini?',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Keluar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isLoggingOut = true;
    });

    String? logoutError;

    try {
      await _customerService.logout(NotificationService.instance.currentFid);
    } catch (_) {
      logoutError =
          'Koneksi ke server gagal. Sesi lokal telah diakhiri, '
          'namun pencabutan token di server belum dapat dipastikan.';
    }

    if (!mounted) return;

    if (widget.onLoggedOut != null) {
      widget.onLoggedOut!();
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }

    if (logoutError != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(logoutError),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Profil Saya',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            tooltip: 'Muat ulang data',
            onPressed: _reloadProfile,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigation(),
      body: FutureBuilder<CustomerAccount>(
        future: _accountFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_off_outlined,
                      size: 64,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Gagal Memuat Profil',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Periksa koneksi internet atau sesi login Anda, kemudian coba kembali.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _reloadProfile,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          final account = snapshot.data;
          if (account == null) {
            return const Center(
              child: Text('Data profil nasabah tidak tersedia.'),
            );
          }

          final initials = _getInitials(account.studentName);
          final status = account.status;
          final statusLabel = _statusLabel(status);
          final statusColor = _statusColor(status);
          final statusBg = _statusBgColor(status);

          return RefreshIndicator(
            onRefresh: () async {
              final future = _customerService.getAccount();
              setState(() {
                _accountFuture = future;
              });
              await future;
            },
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                // =============================================================
                // 1. PROFILE HEADER
                // =============================================================
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Avatar dengan inisial nama
                      CircleAvatar(
                        radius: 38,
                        backgroundColor: AppTheme.primary,
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Nama Siswa
                      Text(
                        account.studentName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // NIS & Kelas
                      Text(
                        'NIS: ${account.studentNumber} • ${account.className}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Badge Status Rekening
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Rekening $statusLabel',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // =============================================================
                // 2. INFORMASI REKENING
                // =============================================================
                _SectionHeader(
                  icon: Icons.account_balance_rounded,
                  title: 'Informasi Rekening',
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _ProfileRow(
                        icon: Icons.credit_card_rounded,
                        label: 'Nomor Rekening',
                        value: account.accountNumber,
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.copy_rounded,
                            size: 18,
                            color: AppTheme.primary,
                          ),
                          tooltip: 'Salin Nomor Rekening',
                          onPressed: () => _copyToClipboard(
                            account.accountNumber,
                            'Nomor rekening',
                          ),
                        ),
                      ),
                      const Divider(height: 1, indent: 56),
                      _ProfileRow(
                        icon: Icons.person_outline_rounded,
                        label: 'Nama Pemilik Rekening',
                        value: account.studentName,
                      ),
                      const Divider(height: 1, indent: 56),
                      _ProfileRow(
                        icon: Icons.account_balance_wallet_outlined,
                        label: 'Saldo Rekening',
                        value: _formatRupiah(account.balance),
                        valueColor: const Color(0xFF059669),
                        isBold: true,
                      ),
                      const Divider(height: 1, indent: 56),
                      _ProfileRow(
                        icon: Icons.school_outlined,
                        label: 'Kelas / Jurusan',
                        value: account.className,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // =============================================================
                // 3. INFORMASI AKUN
                // =============================================================
                _SectionHeader(
                  icon: Icons.manage_accounts_rounded,
                  title: 'Informasi Akun',
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _ProfileRow(
                        icon: Icons.badge_outlined,
                        label: 'Username Login (NIS)',
                        value: account.studentNumber.isEmpty
                            ? '-'
                            : account.studentNumber,
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.copy_rounded,
                            size: 18,
                            color: AppTheme.primary,
                          ),
                          tooltip: 'Salin NIS',
                          onPressed: () =>
                              _copyToClipboard(account.studentNumber, 'NIS'),
                        ),
                      ),
                      const Divider(height: 1, indent: 56),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.mark_email_read_outlined,
                              color: AppTheme.primary,
                              size: 22,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Email Pemulihan',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  if (account.recoveryEmail != null &&
                                      account.recoveryEmail!.isNotEmpty) ...[
                                    Text(
                                      account.recoveryEmail!,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          account.recoveryEmailVerified
                                              ? Icons.check_circle_rounded
                                              : Icons.pending_rounded,
                                          size: 14,
                                          color: account.recoveryEmailVerified
                                              ? const Color(0xFF10B981)
                                              : const Color(0xFFF59E0B),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          account.recoveryEmailVerified
                                              ? 'Email terverifikasi'
                                              : 'Menunggu verifikasi',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: account.recoveryEmailVerified
                                                ? const Color(0xFF10B981)
                                                : const Color(0xFFF59E0B),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        size: 14,
                                      ),
                                      label: const Text(
                                        'Ubah Email',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      onPressed: () =>
                                          _showRequestRecoveryEmailDialog(
                                            account.recoveryEmail,
                                          ),
                                    ),
                                    if (!account.recoveryEmailVerified) ...[
                                      const SizedBox(height: 8),
                                      TextButton.icon(
                                        onPressed: () =>
                                            _verifyCurrentRecoveryEmail(
                                              account.recoveryEmail!,
                                            ),
                                        icon: const Icon(
                                          Icons.verified_outlined,
                                          size: 16,
                                        ),
                                        label: const Text('Verifikasi Email'),
                                      ),
                                    ],
                                  ] else ...[
                                    const Text(
                                      'Belum memiliki email pemulihan',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontStyle: FontStyle.italic,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Tambahkan email pemulihan untuk menerima OTP saat lupa password.',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    FilledButton.icon(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: AppTheme.primary,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.add_circle_outline,
                                        size: 14,
                                      ),
                                      label: const Text(
                                        'Tambah Email Pemulihan',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      onPressed: () =>
                                          _showRequestRecoveryEmailDialog(null),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, indent: 56),
                      _ProfileRow(
                        icon: Icons.verified_user_outlined,
                        label: 'Status Akun Pengguna',
                        value: statusLabel,
                        valueColor: statusColor,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // =============================================================
                // 4. PENGATURAN & KEAMANAN AKUN
                // =============================================================
                _SectionHeader(
                  icon: Icons.shield_outlined,
                  title: 'Keamanan Akun & Transaksi',
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Legacy reset flags must continue through the OTP recovery flow.
                      if (account.mustChangePin) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFF59E0B)),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Color(0xFFD97706),
                                size: 24,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Untuk keamanan, pemulihan PIN harus diselesaikan melalui verifikasi OTP ke email terdaftar.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF92400E),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      _PinStatusBanner(
                        hasPin: account.hasPin,
                        isLocked: account.pinLocked,
                        recoveryInProgress: account.pinRecoveryInProgress,
                        mustChangePin: account.mustChangePin,
                        canRecover: account.recoveryEmailVerified,
                        accountActive: account.status.toLowerCase() == 'active',
                        onCreatePin: _openPinSetup,
                        onRecoverPin: () => _openPinRecovery(account),
                      ),

                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 14),

                      // Panduan / Tips Keamanan
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.privacy_tip_outlined,
                            size: 20,
                            color: AppTheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Panduan Keamanan Akun',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '• Jangan pernah membagikan password atau PIN kepada siapa pun.\n'
                                  '• Petugas bank tidak pernah meminta password atau PIN nasabah.\n'
                                  '• Jika lupa PIN transaksi, pulihkan secara mandiri melalui OTP ke email terverifikasi.',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    height: 1.45,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // =============================================================
                // 5. INFORMASI APLIKASI
                // =============================================================
                _SectionHeader(
                  icon: Icons.info_outline_rounded,
                  title: 'Informasi Aplikasi',
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: const [
                      _ProfileRow(
                        icon: Icons.account_balance_rounded,
                        label: 'Aplikasi',
                        value: 'E-Teller Bank Mini Sekolah',
                      ),
                      Divider(height: 1, indent: 56),
                      _ProfileRow(
                        icon: Icons.code_rounded,
                        label: 'Versi Aplikasi',
                        value: 'v1.0.0 (Production Build)',
                      ),
                      Divider(height: 1, indent: 56),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                _SectionHeader(
                  icon: Icons.help_outline_rounded,
                  title: 'Bantuan',
                ),
                const SizedBox(height: 8),
                Card(
                  margin: EdgeInsets.zero,
                  color: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFFEAECF0)),
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFEEF3FF),
                      child: Icon(
                        Icons.menu_book_outlined,
                        color: AppTheme.primary,
                      ),
                    ),
                    title: const Text(
                      'Pusat Bantuan',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Panduan penggunaan dan pertanyaan umum',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => const HelpCenterScreen(),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 28),

                // =============================================================
                // 6. LOGOUT
                // =============================================================
                OutlinedButton.icon(
                  onPressed: _isLoggingOut ? null : _confirmLogout,
                  icon: _isLoggingOut
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFEF4444),
                          ),
                        )
                      : const Icon(Icons.logout_rounded, size: 20),
                  label: Text(
                    _isLoggingOut ? 'Sedang Keluar...' : 'Keluar dari Akun',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                    side: const BorderSide(
                      color: Color(0xFFEF4444),
                      width: 1.2,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.isBold = false,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool isBold;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                    color: valueColor ?? AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _PinStatusBanner extends StatelessWidget {
  const _PinStatusBanner({
    required this.hasPin,
    required this.isLocked,
    required this.recoveryInProgress,
    required this.mustChangePin,
    required this.canRecover,
    required this.accountActive,
    required this.onCreatePin,
    required this.onRecoverPin,
  });

  final bool hasPin;
  final bool isLocked;
  final bool recoveryInProgress;
  final bool mustChangePin;
  final bool canRecover;
  final bool accountActive;
  final VoidCallback onCreatePin;
  final VoidCallback onRecoverPin;

  @override
  Widget build(BuildContext context) {
    final needsRecovery = isLocked || mustChangePin;
    final needsInitialSetup = !hasPin && !needsRecovery;
    final color = needsInitialSetup
        ? const Color(0xFFD97706)
        : needsRecovery
        ? const Color(0xFFDC2626)
        : const Color(0xFF059669);
    final background = needsInitialSetup
        ? const Color(0xFFFFFBEB)
        : needsRecovery
        ? const Color(0xFFFEF2F2)
        : const Color(0xFFECFDF5);
    final title = needsInitialSetup
        ? 'PIN Transaksi Belum Dibuat'
        : needsRecovery
        ? 'PIN Transaksi Terkunci'
        : 'PIN Transaksi Aktif';
    final description = needsInitialSetup
        ? 'Kamu belum memiliki PIN transaksi. Buat PIN 6 digit terlebih dahulu agar dapat melakukan penarikan.'
        : needsRecovery
        ? 'Pulihkan PIN melalui verifikasi OTP email sebelum menggunakannya untuk transaksi.'
        : 'PIN transaksi kamu sudah berhasil dibuat dan dapat digunakan untuk konfirmasi penarikan.';

    return Container(
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                !hasPin
                    ? Icons.lock_open_rounded
                    : needsRecovery
                    ? Icons.lock_reset_rounded
                    : Icons.lock_person_rounded,
                color: color,
                size: 23,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    if (recoveryInProgress && hasPin) ...[
                      const SizedBox(height: 6),
                      const Text(
                        'Pemulihan PIN sedang berlangsung. Lanjutkan melalui menu Kelola PIN.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF92400E),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: needsInitialSetup
                ? FilledButton.icon(
                    onPressed: accountActive ? onCreatePin : null,
                    icon: const Icon(Icons.add_moderator_rounded, size: 18),
                    label: const Text('Buat PIN'),
                  )
                : OutlinedButton.icon(
                    onPressed: canRecover ? onRecoverPin : null,
                    icon: Icon(
                      needsRecovery
                          ? Icons.lock_reset_rounded
                          : Icons.manage_accounts_outlined,
                      size: 18,
                    ),
                    label: Text(needsRecovery ? 'Pulihkan PIN' : 'Kelola PIN'),
                  ),
          ),
          if (hasPin && !canRecover) ...[
            const SizedBox(height: 6),
            const Text(
              'Verifikasi email pemulihan terlebih dahulu untuk mengelola atau memulihkan PIN.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// DIALOG 2: REQUEST EMAIL PEMULIHAN
// =============================================================================

class _RequestRecoveryEmailDialog extends StatefulWidget {
  const _RequestRecoveryEmailDialog({
    required this.currentEmail,
    required this.customerService,
  });

  final String? currentEmail;
  final CustomerService customerService;

  @override
  State<_RequestRecoveryEmailDialog> createState() =>
      _RequestRecoveryEmailDialogState();
}

class _RequestRecoveryEmailDialogState
    extends State<_RequestRecoveryEmailDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final response = await widget.customerService.requestRecoveryEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final data = response['data'];
      final challengeId = data is Map<String, dynamic>
          ? int.tryParse(data['challenge_id']?.toString() ?? '')
          : null;
      if (challengeId == null) {
        throw CustomerApiException(
          message: 'Server tidak mengembalikan identitas permintaan OTP.',
          statusCode: 200,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop({
        'email': _emailController.text.trim(),
        'challenge_id': challengeId,
      });
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        widget.currentEmail == null
            ? 'Tambah Email Pemulihan'
            : 'Ubah Email Pemulihan',
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Email pemulihan digunakan untuk menerima kode OTP jika Anda lupa password.',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                enabled: !_isSubmitting,
                decoration: const InputDecoration(
                  labelText: 'Email Baru',
                  hintText: 'nama@example.com',
                  prefixIcon: Icon(Icons.email_outlined, size: 20),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Email wajib diisi.';
                  }
                  final trimmed = value.trim();
                  if (!RegExp(
                    r'^[\w\.-]+@[\w\.-]+\.\w{2,}$',
                  ).hasMatch(trimmed)) {
                    return 'Format email tidak valid.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                enabled: !_isSubmitting,
                decoration: InputDecoration(
                  labelText: 'Password Akun Saat Ini',
                  hintText: 'Konfirmasi identitas nasabah',
                  prefixIcon: const Icon(Icons.lock_outline, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                    ),
                    onPressed: _isSubmitting
                        ? null
                        : () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password akun wajib diisi.';
                  }
                  return null;
                },
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
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Kirim OTP'),
        ),
      ],
    );
  }
}

// =============================================================================
// DIALOG 3: VERIFIKASI OTP EMAIL PEMULIHAN
// =============================================================================

class _VerifyRecoveryEmailOtpDialog extends StatefulWidget {
  const _VerifyRecoveryEmailOtpDialog({
    required this.newEmail,
    required this.challengeId,
    required this.customerService,
  });

  final String newEmail;
  final int challengeId;
  final CustomerService customerService;

  @override
  State<_VerifyRecoveryEmailOtpDialog> createState() =>
      _VerifyRecoveryEmailOtpDialogState();
}

class _VerifyRecoveryEmailOtpDialogState
    extends State<_VerifyRecoveryEmailOtpDialog> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await widget.customerService.verifyRecoveryEmail(
        otp: _otpController.text.trim(),
        challengeId: widget.challengeId,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on CustomerApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _isSubmitting = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Verifikasi gagal. Silakan coba kembali.';
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Verifikasi OTP Email'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kode OTP 6 digit telah dikirim ke ${widget.newEmail}. Masukkan kode berikut untuk memverifikasi email.',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 6,
                enabled: !_isSubmitting,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  letterSpacing: 8,
                  fontWeight: FontWeight.bold,
                ),
                decoration: const InputDecoration(
                  labelText: 'Kode OTP 6 Digit',
                  counterText: '',
                  prefixIcon: Icon(Icons.pin_outlined, size: 20),
                ),
                validator: (value) {
                  if (value == null || value.trim().length != 6) {
                    return 'Masukkan 6 digit angka OTP.';
                  }
                  return null;
                },
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
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting
              ? null
              : () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Verifikasi'),
        ),
      ],
    );
  }
}
