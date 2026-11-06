import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../models/customer_account.dart';
import '../../services/customer_service.dart';

class QrRekeningScreen extends StatefulWidget {
  const QrRekeningScreen({super.key});

  static const Color primary = Color(0xFF003FB3);
  static const Color primaryDark = Color(0xFF002B81);
  static const Color background = Color(0xFFF8F9FE);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);

  @override
  State<QrRekeningScreen> createState() => _QrRekeningScreenState();
}

class _QrRekeningScreenState extends State<QrRekeningScreen> {
  final CustomerService _customerService = CustomerService();

  CustomerAccount? _account;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAccount();
  }

  Future<void> _loadAccount() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final account = await _customerService.getAccount();

      if (!mounted) return;

      setState(() {
        _account = account;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error
            .toString()
            .replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _copyAccountNumber() async {
    final account = _account;
    if (account == null) return;

    await Clipboard.setData(
      ClipboardData(text: account.accountNumber),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Nomor rekening berhasil disalin.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildInformationRow({
    required String label,
    required String value,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: QrRekeningScreen.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    value,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: QrRekeningScreen.textPrimary,
                    ),
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 4),
                  trailing,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          child: SizedBox(
            height: 48,
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: QrRekeningScreen.textPrimary,
                  ),
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    size: 18,
                  ),
                ),
                const Expanded(
                  child: Text(
                    'QR Rekening Saya',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: QrRekeningScreen.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: QrRekeningScreen.primary,
          ),
          SizedBox(height: 16),
          Text(
            'Memuat data rekening...',
            style: TextStyle(
              color: QrRekeningScreen.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 56,
              color: QrRekeningScreen.textSecondary,
            ),
            const SizedBox(height: 16),
            const Text(
              'Data Rekening Belum Tersedia',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: QrRekeningScreen.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Terjadi kesalahan saat memuat rekening.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: QrRekeningScreen.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadAccount,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: QrRekeningScreen.primary,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Kembali'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(CustomerAccount account) {
    final bool isActive = account.status.toLowerCase() == 'active';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Identitas bank mini.
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 12,
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
                        color: QrRekeningScreen.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.account_balance,
                        color: Colors.white,
                        size: 23,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Layanan Perbankan Siswa',
                            style: TextStyle(
                              fontSize: 11,
                              color: QrRekeningScreen.textSecondary,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Bank Mini SMKN 1 Bantul',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: QrRekeningScreen.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFFECFDF5)
                            : const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.circle,
                            color: isActive
                                ? const Color(0xFF10B981)
                                : const Color(0xFFF59E0B),
                            size: 8,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            account.status,
                            style: TextStyle(
                              color: isActive
                                  ? const Color(0xFF047857)
                                  : const Color(0xFF9A3412),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Kartu QR rekening.
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.035),
                      blurRadius: 18,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.qr_code_scanner,
                          color: QrRekeningScreen.primary,
                          size: 22,
                        ),
                        SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            'QR Identifikasi Nasabah',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: QrRekeningScreen.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: QrImageView(
                        data: account.accountNumber,
                        version: QrVersions.auto,
                        size: 220,
                        backgroundColor: Colors.white,
                        errorCorrectionLevel: QrErrorCorrectLevel.H,
                      ),
                    ),

                    const SizedBox(height: 14),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Payload: ${account.accountNumber}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w600,
                          color: QrRekeningScreen.textPrimary,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    const Divider(color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 8),

                    _buildInformationRow(
                      label: 'Nama Nasabah',
                      value: account.studentName,
                    ),

                    _buildInformationRow(
                      label: 'Nomor Rekening',
                      value: account.accountNumber,
                      trailing: IconButton(
                        onPressed: _copyAccountNumber,
                        tooltip: 'Salin nomor rekening',
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        padding: EdgeInsets.zero,
                        icon: const Icon(
                          Icons.copy,
                          size: 17,
                          color: QrRekeningScreen.primary,
                        ),
                      ),
                    ),

                    _buildInformationRow(
                      label: 'Status Rekening',
                      value: account.status,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Panduan penggunaan QR.
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF4FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: QrRekeningScreen.primaryDark,
                      size: 23,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tunjukkan QR ini kepada Teller',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: QrRekeningScreen.primaryDark,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Teller akan memindai QR untuk '
                            'mengidentifikasi rekening Anda. '
                            'Setoran dan penarikan tetap diproses '
                            'melalui website teller.',
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.6,
                              color: QrRekeningScreen.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.home_outlined),
                  label: const Text('Kembali ke Beranda'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: QrRekeningScreen.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _customerService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QrRekeningScreen.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? _buildLoading()
                  : _errorMessage != null
                      ? _buildError()
                      : _account == null
                          ? _buildError()
                          : _buildContent(_account!),
            ),
          ],
        ),
      ),
    );
  }
}
