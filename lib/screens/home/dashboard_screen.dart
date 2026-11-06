import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../models/customer_account.dart';
import '../../models/customer_transaction.dart';
import '../../services/customer_service.dart';
import '../transactions/mutasi_screen.dart';
import '../transactions/persetujuan_screen.dart';
import '../profile/profile_screen.dart';
import '../profile/pin_setup_screen.dart';
import 'qr_rekening_screen.dart';
import '../../widgets/notification_bottom_sheet.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, this.customerService, this.initialAccount});

  final CustomerService? customerService;
  final CustomerAccount? initialAccount;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // =====================================================
  // STATE DASHBOARD
  // =====================================================

  late final CustomerService _customerService;
  late final bool _ownsCustomerService;

  CustomerAccount? _account;
  List<CustomerTransaction> _transactions = [];
  bool _useInitialAccount = false;

  bool _isLoading = true;
  bool _isBalanceVisible = true;

  String? _errorMessage;

  int _selectedIndex = 0;
  Timer? _notificationPollingTimer;
  final Set<int> _knownPendingIds = {};

  List<CustomerTransaction> get _pendingTransactions {
    return _transactions.where((transaction) => transaction.isPending).toList();
  }

  @override
  void initState() {
    super.initState();

    _ownsCustomerService = widget.customerService == null;
    _customerService = widget.customerService ?? CustomerService();
    _account = widget.initialAccount;
    _useInitialAccount = widget.initialAccount != null;
    _loadDashboard();
    _startPollingNotifications();
  }

  @override
  void dispose() {
    _notificationPollingTimer?.cancel();
    if (_ownsCustomerService) _customerService.dispose();
    super.dispose();
  }

  // =====================================================
  // AMBIL DATA DASHBOARD DARI API
  // =====================================================

  Future<void> _loadDashboard({bool refresh = false}) async {
    if (!mounted) return;

    setState(() {
      if (!refresh) {
        _isLoading = true;
      }

      _errorMessage = null;
    });

    try {
      final accountFuture = _useInitialAccount
          ? Future<CustomerAccount>.value(_account!)
          : _customerService.getAccount();
      _useInitialAccount = false;

      final results = await Future.wait([
        accountFuture,
        _customerService.getTransactions(),
      ]);

      final account = results[0] as CustomerAccount;
      final transactions = results[1] as List<CustomerTransaction>;
      _knownPendingIds.clear();
      for (final t in transactions.where((t) => t.isPending)) {
        _knownPendingIds.add(t.id);
      }

      if (!mounted) return;

      setState(() {
        _account = account;
        _transactions = transactions;
        _isLoading = false;

        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;

        _errorMessage = _cleanErrorMessage(error);
      });
    }
  }

  String _cleanErrorMessage(Object error) {
    return error
        .toString()
        .replaceFirst('Exception: ', '')
        .replaceFirst('FormatException: ', '');
  }

  // =====================================================
  // POLLING NOTIFIKASI PERMINTAAN PERSETUJUAN
  // =====================================================

  void _startPollingNotifications() {
    _notificationPollingTimer?.cancel();
    _notificationPollingTimer = Timer.periodic(
      const Duration(seconds: 4),
      (_) => _silentCheckNewPendingTransactions(),
    );
  }

  Future<void> _silentCheckNewPendingTransactions() async {
    if (!mounted) return;

    try {
      final transactions = await _customerService.getTransactions();
      if (!mounted) return;

      final newPending = transactions.where((t) => t.isPending).toList();
      final hasNew = newPending.any((t) => !_knownPendingIds.contains(t.id));

      if (hasNew) {
        // Berikan getaran haptik untuk menarik perhatian nasabah
        HapticFeedback.heavyImpact();

        final firstNew = newPending.firstWhere(
          (t) => !_knownPendingIds.contains(t.id),
        );

        // Guard mounted lagi sebelum mengakses context (widget bisa dispose
        // di antara await getTransactions() dan baris ini).
        if (!mounted) return;

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF131B2E),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: const BoxDecoration(
                    color: Color(0xFFD97706),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_active_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Permintaan Persetujuan',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${firstNew.transactionTypeLabel} ${_formatRupiah(firstNew.amount)} membutuhkan PIN Anda.',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFDCE7FF),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            action: SnackBarAction(
              label: 'KONFIRMASI',
              textColor: const Color(0xFFFDE68A),
              onPressed: () {
                if (!mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PersetujuanScreen(),
                  ),
                ).then((_) {
                  if (mounted) _loadDashboard(refresh: true);
                });
              },
            ),
          ),
        );
      }

      _knownPendingIds.clear();
      for (final t in newPending) {
        _knownPendingIds.add(t.id);
      }

      if (!mounted) return;
      setState(() {
        _transactions = transactions;
      });
    } catch (_) {
      // Polling tidak menampilkan dialog error blocking
    }
  }

  // =====================================================
  // DATA REKENING
  // =====================================================

  String get _studentName {
    return _account?.studentName ?? 'Nasabah';
  }

  String get _accountNumber {
    return _account?.accountNumber ?? '';
  }

  int get _balance {
    return _account?.balance ?? 0;
  }

  String get _accountStatus {
    final status = _account?.status.toLowerCase();

    if (status == 'active' || status == 'aktif') {
      return 'Aktif';
    }

    if (status == 'blocked' || status == 'diblokir') {
      return 'Diblokir';
    }

    if (status == null || status.isEmpty) {
      return 'Tidak diketahui';
    }

    return _account!.status;
  }

  bool get _isAccountActive {
    final status = _account?.status.toLowerCase();

    return status == 'active' || status == 'aktif';
  }

  // =====================================================
  // FORMAT RUPIAH
  // =====================================================

  String _formatRupiah(int amount) {
    final formatted = amount.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );

    return 'Rp $formatted';
  }

  // =====================================================
  // FORMAT TANGGAL DAN WAKTU
  // =====================================================

  String _formatTransactionDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    final localDate = date.toLocal();

    return '${localDate.day} '
        '${months[localDate.month - 1]} '
        '${localDate.year}';
  }

  String _formatTransactionTime(DateTime date) {
    final localDate = date.toLocal();

    final hour = localDate.hour.toString().padLeft(2, '0');
    final minute = localDate.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  // =====================================================
  // SALIN NOMOR REKENING
  // =====================================================

  Future<void> _copyAccountNumber() async {
    if (_accountNumber.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: _accountNumber));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Nomor rekening berhasil disalin.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // =====================================================
  // NAVIGASI
  // =====================================================

  void _openQrRekening() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QrRekeningScreen()),
    );
  }

  Future<void> _openPinSetup() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => PinSetupScreen(customerService: _customerService),
      ),
    );

    if (created == true && mounted) {
      await _loadDashboard(refresh: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PIN transaksi berhasil dibuat dan aktif.'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    }
  }

  void _openPinManagement() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
    );
  }

  void _onNavigationTap(int index) {
    if (index == 0) {
      setState(() {
        _selectedIndex = 0;
      });

      _loadDashboard(refresh: true);
      return;
    }

    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MutasiScreen()),
      );
      return;
    }

    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PersetujuanScreen()),
      );
      return;
    }

    if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfileScreen()),
      );
    }
  }

  // =====================================================
  // BUILD DASHBOARD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: SafeArea(bottom: false, child: _buildBody()),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _account == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _account == null) {
      return _buildErrorState();
    }

    return RefreshIndicator(
      onRefresh: () => _loadDashboard(refresh: true),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_errorMessage != null) ...[
              _buildRefreshErrorBanner(),
              const SizedBox(height: 12),
            ],

            _buildHeader(),

            const SizedBox(height: 20),

            if (!_isAccountActive && _account != null) ...[
              _buildBlockedAccountBanner(),
              const SizedBox(height: 16),
            ],

            if (_account != null && _shouldShowPinBanner) ...[
              _buildPinStatusBanner(),
              const SizedBox(height: 16),
            ],

            _buildBalanceCard(),

            const SizedBox(height: 16),

            _buildPendingApproval(),

            const SizedBox(height: 24),

            _buildTransactionHeader(),

            const SizedBox(height: 12),

            _buildTransactionList(),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  bool get _shouldShowPinBanner {
    final account = _account;
    if (account == null) return false;

    return !account.hasPin ||
        account.pinLocked ||
        account.pinRecoveryInProgress ||
        account.hasPendingPinReset ||
        account.mustChangePin;
  }

  Widget _buildPinStatusBanner() {
    final account = _account!;
    final isRecoveryPending =
        account.pinRecoveryInProgress || account.hasPendingPinReset;
    final needsRecovery = account.pinLocked || account.mustChangePin;
    final isLocked = needsRecovery && !isRecoveryPending;
    final color = isRecoveryPending
        ? const Color(0xFFB45309)
        : isLocked
        ? const Color(0xFFDC2626)
        : const Color(0xFFD97706);
    final background = isRecoveryPending
        ? const Color(0xFFFFFBEB)
        : isLocked
        ? const Color(0xFFFEF2F2)
        : const Color(0xFFFFFBEB);
    final title = isRecoveryPending
        ? 'Pemulihan PIN Sedang Diproses'
        : isLocked
        ? 'PIN Transaksi Terkunci'
        : 'PIN Transaksi Belum Dibuat';
    final description = isRecoveryPending
        ? 'Permintaan pemulihan PIN kamu sedang diproses. Lihat status dan lanjutkan melalui menu Keamanan PIN Transaksi.'
        : isLocked
        ? 'Pulihkan PIN melalui verifikasi OTP email sebelum menggunakannya untuk transaksi.'
        : 'Kamu sudah memiliki rekening. Buat PIN transaksi 6 digit terlebih dahulu agar dapat melakukan penarikan tunai.';
    final canCreatePin =
        !account.hasPin && !needsRecovery && !isRecoveryPending;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isRecoveryPending
                ? Icons.hourglass_top_rounded
                : isLocked
                ? Icons.lock_reset_rounded
                : Icons.lock_open_rounded,
            color: color,
            size: 22,
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
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: canCreatePin
                      ? FilledButton.tonal(
                          onPressed: _isAccountActive ? _openPinSetup : null,
                          child: const Text('Buat PIN Sekarang'),
                        )
                      : TextButton(
                          onPressed: _openPinManagement,
                          child: const Text('Kelola PIN'),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 52,
              color: Color(0xFF9298A7),
            ),
            const SizedBox(height: 16),
            const Text(
              'Data dashboard gagal dimuat',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Terjadi kesalahan.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF9298A7)),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => _loadDashboard(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRefreshErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFB7791F)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Gagal memperbarui data: $_errorMessage',
              style: const TextStyle(fontSize: 12, color: Color(0xFF8A5A10)),
            ),
          ),
          IconButton(
            onPressed: () => _loadDashboard(refresh: true),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Coba lagi',
          ),
        ],
      ),
    );
  }

  Widget _buildBlockedAccountBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECACA), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFDC2626).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.gpp_bad_rounded,
              color: Color(0xFFDC2626),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rekening Sedang Diblokir',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF991B1B),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Rekening Anda diblokir sementara demi keamanan (salah PIN 3 kali). '
                  'Silakan hubungi Petugas / Admin Bank Mini Sekolah untuk mengaktifkan kembali rekening.',
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.45,
                    color: Color(0xFF7F1D1D),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // 1. HEADER & NOTIFIKASI
  // =====================================================

  void _showNotificationSheet() {
    NotificationBottomSheet.show(
      context,
      pendingTransactions: _pendingTransactions,
      recentTransactions: _transactions.take(5).toList(),
      onOpenPersetujuan: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PersetujuanScreen()),
        ).then((_) {
          _loadDashboard(refresh: true);
        });
      },
      formatRupiah: _formatRupiah,
      formatDate: _formatTransactionDate,
      formatTime: _formatTransactionTime,
    );
  }

  Widget _buildNotificationBell() {
    final hasPending = _pendingTransactions.isNotEmpty;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFF0F1F5)),
          ),
          child: IconButton(
            tooltip: 'Pusat Notifikasi',
            onPressed: _showNotificationSheet,
            icon: Icon(
              hasPending
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_none_rounded,
              size: 22,
              color: hasPending
                  ? const Color(0xFFD97706)
                  : const Color(0xFF434653),
            ),
          ),
        ),
        if (hasPending)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Text(
                '${_pendingTransactions.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bank Mini SMKN 1 Bantul',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF8A90A0),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Halo, $_studentName',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _buildNotificationBell(),
        const SizedBox(width: 10),
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppTheme.primary,
            shape: BoxShape.circle,
          ),
          child: Text(
            _getInitials(_studentName),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  String _getInitials(String name) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();

    if (words.isEmpty) return '';

    if (words.length == 1) {
      return words.first.substring(0, 1).toUpperCase();
    }

    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }

  // =====================================================
  // 2. KARTU SALDO
  // =====================================================

  Widget _buildBalanceCard() {
    final maskedAccountNumber = _accountNumber.isEmpty
        ? '•••• •••• ----'
        : '•••• •••• ${_accountNumber.length >= 4 ? _accountNumber.substring(_accountNumber.length - 4) : _accountNumber}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF003FB3), Color(0xFF003494), Color(0xFF00246B)],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF002B81).withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -16,
            bottom: 38,
            child: Icon(
              Icons.account_balance_rounded,
              size: 150,
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Saldo Rekening',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.82),
                    ),
                  ),
                  Material(
                    color: Colors.white.withValues(alpha: 0.12),
                    shape: const CircleBorder(),
                    child: IconButton(
                      tooltip: _isBalanceVisible
                          ? 'Sembunyikan saldo'
                          : 'Tampilkan saldo',
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        setState(() {
                          _isBalanceVisible = !_isBalanceVisible;
                        });
                      },
                      icon: Icon(
                        _isBalanceVisible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 19,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _isBalanceVisible ? _formatRupiah(_balance) : 'Rp ••••••••',
                style: const TextStyle(
                  fontSize: 31,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.9,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            maskedAccountNumber,
                            style: const TextStyle(
                              fontSize: 13,
                              letterSpacing: 1.1,
                              color: Color(0xFFD8E3FF),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: _copyAccountNumber,
                          borderRadius: BorderRadius.circular(8),
                          child: const Padding(
                            padding: EdgeInsets.all(5),
                            child: Icon(
                              Icons.content_copy_rounded,
                              size: 14,
                              color: Color(0xFFD8E3FF),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.circle,
                          size: 7,
                          color: _isAccountActive
                              ? const Color(0xFF6EE7B7)
                              : const Color(0xFFFCA5A5),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _accountStatus,
                          style: TextStyle(
                            color: _isAccountActive
                                ? const Color(0xFFB9F8D7)
                                : const Color(0xFFFECACA),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(height: 1, color: Colors.white.withValues(alpha: 0.18)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildBalanceAction(
                      icon: Icons.qr_code_rounded,
                      label: 'QR Rekening Saya',
                      onTap: _openQrRekening,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildBalanceAction(
                      icon: Icons.receipt_long_outlined,
                      label: 'Mutasi',
                      onTap: () => _onNavigationTap(1),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 42,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: Colors.white),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =====================================================
  // 3. PERMINTAAN PERSETUJUAN
  // =====================================================

  Widget _buildPendingApproval() {
    final pending = _pendingTransactions;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE7FF)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF003FB3).withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEDF3FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.pending_actions_rounded,
              color: Color(0xFF003FB3),
              size: 23,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PERMINTAAN PERSETUJUAN',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 0.2,
                    color: Color(0xFF003FB3),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  pending.isNotEmpty
                      ? '${pending.length} transaksi menunggu'
                      : 'Tidak ada transaksi tertunda',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF202536),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  pending.isNotEmpty
                      ? '${pending.first.transactionTypeLabel} • ${_formatRupiah(pending.first.amount)}'
                      : 'Semua transaksi telah diproses',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF8A90A0),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  pending.isNotEmpty
                      ? 'Menunggu persetujuan'
                      : 'Status transaksi aman',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: pending.isNotEmpty
                        ? const Color(0xFFB7791F)
                        : const Color(0xFF16865B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 34,
            child: FilledButton(
              onPressed: () => _onNavigationTap(2),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'Lihat',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // 4. HEADER TRANSAKSI TERBARU
  // =====================================================

  Widget _buildTransactionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Transaksi Terbaru',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: AppTheme.textPrimary,
          ),
        ),
        TextButton(
          onPressed: () => _onNavigationTap(1),
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.primary,
            padding: const EdgeInsets.symmetric(horizontal: 4),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Lihat Semua',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              SizedBox(width: 2),
              Icon(Icons.chevron_right_rounded, size: 18),
            ],
          ),
        ),
      ],
    );
  }

  // =====================================================
  // 5. DAFTAR TRANSAKSI
  // =====================================================

  Widget _buildTransactionList() {
    if (_transactions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFEEF0F5)),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 32,
              color: Color(0xFF9298A7),
            ),
            SizedBox(height: 8),
            Text(
              'Belum ada transaksi',
              style: TextStyle(fontSize: 13, color: Color(0xFF9298A7)),
            ),
          ],
        ),
      );
    }

    final recentTransactions = _transactions.take(3).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEEF0F5)),
      ),
      child: Column(
        children: [
          for (int i = 0; i < recentTransactions.length; i++) ...[
            _buildTransactionItem(recentTransactions[i]),
            if (i != recentTransactions.length - 1)
              const Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: Color(0xFFF0F1F5),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildTransactionItem(CustomerTransaction transaction) {
    final bool isDeposit = transaction.transactionType == 'deposit';
    final bool isCancelled = transaction.status.toLowerCase() == 'cancelled';

    final Color iconBackground = isCancelled
        ? const Color(0xFFFEE2E2)
        : isDeposit
        ? const Color(0xFFE8F8F0)
        : const Color(0xFFFFEEF0);

    final Color iconColor = isCancelled
        ? const Color(0xFFDC2626)
        : isDeposit
        ? const Color(0xFF16865B)
        : const Color(0xFFD94A5B);

    final IconData transactionIcon = isCancelled
        ? Icons.cancel_outlined
        : isDeposit
        ? Icons.arrow_downward_rounded
        : Icons.arrow_upward_rounded;

    final Color statusColor;

    switch (transaction.status) {
      case 'approved':
        statusColor = const Color(0xFF16865B);
        break;
      case 'pending':
        statusColor = const Color(0xFFB7791F);
        break;
      case 'rejected':
        statusColor = const Color(0xFFD94A5B);
        break;
      case 'cancelled':
        statusColor = const Color(0xFFDC2626);
        break;
      default:
        statusColor = const Color(0xFF9298A7);
    }

    final String amountLabel = isCancelled
        ? 'Dibatalkan\n${_formatRupiah(transaction.amount)}'
        : transaction.status == 'rejected'
        ? ''
        : isDeposit
        ? '+'
        : '-';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(transactionIcon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.transactionTypeLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF202536),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${_formatTransactionDate(transaction.transactionDate)} • '
                      '${_formatTransactionTime(transaction.transactionDate)} WIB',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF9298A7),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    isCancelled
                        ? amountLabel
                        : '$amountLabel ${_formatRupiah(transaction.amount)}',
                    textAlign: TextAlign.end,
                    maxLines: isCancelled ? 2 : 1,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isCancelled
                          ? const Color(0xFFDC2626)
                          : isDeposit
                          ? const Color(0xFF16865B)
                          : const Color(0xFF202536),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    transaction.statusLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =====================================================
  // 6. JAM OPERASIONAL
  // =====================================================

  // =====================================================
  // 7. BOTTOM NAVIGATION
  // =====================================================

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Color(0xFFEEF0F5), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 15,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              _buildNavigationItem(
                index: 0,
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Beranda',
              ),
              _buildNavigationItem(
                index: 1,
                icon: Icons.receipt_long_outlined,
                activeIcon: Icons.receipt_long_rounded,
                label: 'Mutasi',
              ),
              _buildNavigationItem(
                index: 2,
                icon: Icons.fact_check_outlined,
                activeIcon: Icons.fact_check_rounded,
                label: 'Persetujuan',
                showNotification: _pendingTransactions.isNotEmpty,
              ),
              _buildNavigationItem(
                index: 3,
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    bool showNotification = false,
  }) {
    final bool isSelected = _selectedIndex == index;

    final Color itemColor = isSelected
        ? AppTheme.primary
        : const Color(0xFF9298A7);

    return Expanded(
      child: InkWell(
        onTap: () => _onNavigationTap(index),
        child: SizedBox(
          height: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    isSelected ? activeIcon : icon,
                    size: 23,
                    color: itemColor,
                  ),
                  if (showNotification)
                    Positioned(
                      right: -3,
                      top: -2,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: itemColor,
                ),
              ),
              const SizedBox(height: 3),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primary : Colors.transparent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
