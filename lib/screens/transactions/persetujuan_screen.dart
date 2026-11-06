import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../models/customer_transaction.dart';
import '../../services/customer_service.dart';
import '../profile/profile_screen.dart';
import 'mutasi_screen.dart';

enum TransactionFilter {
  all,
  deposit,
  withdrawal,
}

class PersetujuanScreen extends StatefulWidget {
  const PersetujuanScreen({super.key});

  @override
  State<PersetujuanScreen> createState() =>
      _PersetujuanScreenState();
}

class _PersetujuanScreenState extends State<PersetujuanScreen> {
  final CustomerService _customerService = CustomerService();

  List<CustomerTransaction> _transactions = [];

  bool _isLoading = true;
  String? _errorMessage;

  TransactionFilter _selectedFilter = TransactionFilter.all;
  int _selectedNavigationIndex = 2;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  @override
  void dispose() {
    _customerService.dispose();
    super.dispose();
  }

  // =========================================================
  // LOAD TRANSACTIONS
  // =========================================================

  Future<void> _loadTransactions() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final transactions = await _customerService.getTransactions();

      if (!mounted) return;

      setState(() {
        _transactions = transactions;
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

  // =========================================================
  // TRANSACTION DETAIL
  // =========================================================

  Future<void> _openTransactionDetail(
    CustomerTransaction transaction,
  ) async {
    if (!mounted) return;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _TransactionDetailSheet(
          transaction: transaction,
          customerService: _customerService,
          formatCurrency: _formatCurrency,
          formatDate: _formatDate,
        );
      },
    );

    if (!mounted || confirmed != true) return;

    // Muat ulang data setelah konfirmasi berhasil.
    await _loadTransactions();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Transaksi berhasil dikonfirmasi.'),
        backgroundColor: Color(0xFF047857),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // =========================================================
  // BOTTOM NAVIGATION
  // =========================================================

  void _onNavigationTap(int index) {
    if (index == 2) {
      setState(() {
        _selectedNavigationIndex = 2;
      });
      return;
    }

    if (index == 0) {
      Navigator.of(context).pop();
      return;
    }

    if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const MutasiScreen(),
        ),
      );
      return;
    }

    if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const ProfileScreen(),
        ),
      );
    }
  }

  // =========================================================
  // FILTER TRANSACTIONS
  // =========================================================

  List<CustomerTransaction> get _pendingTransactions {
    return _transactions
        .where((transaction) => transaction.isPending)
        .toList();
  }

  List<CustomerTransaction> get _filteredTransactions {
    final pending = _pendingTransactions;

    switch (_selectedFilter) {
      case TransactionFilter.deposit:
        return pending
            .where(
              (transaction) =>
                  transaction.transactionType == 'deposit',
            )
            .toList();

      case TransactionFilter.withdrawal:
        return pending
            .where(
              (transaction) =>
                  transaction.transactionType == 'withdrawal',
            )
            .toList();

      case TransactionFilter.all:
        return pending;
    }
  }

  int _countByFilter(TransactionFilter filter) {
    switch (filter) {
      case TransactionFilter.all:
        return _pendingTransactions.length;

      case TransactionFilter.deposit:
        return _pendingTransactions
            .where(
              (transaction) =>
                  transaction.transactionType == 'deposit',
            )
            .length;

      case TransactionFilter.withdrawal:
        return _pendingTransactions
            .where(
              (transaction) =>
                  transaction.transactionType == 'withdrawal',
            )
            .length;
    }
  }

  // =========================================================
  // FORMATTERS
  // =========================================================

  String _formatCurrency(int amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return formatter.format(amount);
  }

  String _formatDate(DateTime date) {
    final localDate = date.toLocal();

    try {
      return DateFormat(
        'dd MMM yyyy, HH:mm',
        'id_ID',
      ).format(localDate);
    } catch (_) {
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

      final day = localDate.day.toString().padLeft(2, '0');
      final month = months[localDate.month - 1];
      final year = localDate.year;
      final hour = localDate.hour.toString().padLeft(2, '0');
      final minute = localDate.minute.toString().padLeft(2, '0');

      return '$day $month $year, $hour:$minute';
    }
  }

  // =========================================================
  // DETAIL ROW
  // =========================================================

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF747685),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF131B2E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // MAIN SCREEN
  // =========================================================

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFFFAF8FF);
    const primaryColor = Color(0xFF002B81);
    const primaryContainer = Color(0xFF003FB3);
    const textColor = Color(0xFF131B2E);
    const secondaryTextColor = Color(0xFF747685);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: textColor,
          ),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Persetujuan Transaksi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Permintaan transaksi dari loket teller',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: secondaryTextColor,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(
        primaryColor: primaryColor,
        secondaryTextColor: secondaryTextColor,
      ),
      body: SafeArea(
        top: false,
        child: _buildBody(
          primaryColor: primaryColor,
          primaryContainer: primaryContainer,
          textColor: textColor,
          secondaryTextColor: secondaryTextColor,
        ),
      ),
    );
  }

  // =========================================================
  // BOTTOM NAVIGATION BAR
  // =========================================================

Widget _buildBottomNavigation({
  required Color primaryColor,
  required Color secondaryTextColor,
}) {
  const destinations = [
    (
      label: 'Beranda',
      icon: Icons.home_outlined,
    ),
    (
      label: 'Mutasi',
      icon: Icons.receipt_long_rounded,
    ),
    (
      label: 'Persetujuan',
      icon: Icons.fact_check_outlined,
    ),
    (
      label: 'Profil',
      icon: Icons.person_outline_rounded,
    ),
  ];

  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      border: const Border(
        top: BorderSide(
          color: Color(0xFFE2E7FF),
        ),
      ),
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
          children: List.generate(
            destinations.length,
            (index) {
              final destination = destinations[index];
              final isSelected =
                  _selectedNavigationIndex == index;

              return Expanded(
                child: InkWell(
                  onTap: () => _onNavigationTap(index),
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            destination.icon,
                            size: 22,
                            color: isSelected
                                ? primaryColor
                                : secondaryTextColor,
                          ),
                          if (index == 2 &&
                              _pendingTransactions.isNotEmpty)
                            Positioned(
                              top: -2,
                              right: -5,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration:
                                    const BoxDecoration(
                                  color:
                                      Color(0xFFBA1A1A),
                                  shape:
                                      BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        destination.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isSelected
                              ? primaryColor
                              : secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    ),
  );
}
  // =========================================================
  // BODY
  // =========================================================

  Widget _buildBody({
    required Color primaryColor,
    required Color primaryContainer,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 48,
                color: Color(0xFF747685),
              ),
              const SizedBox(height: 16),
              const Text(
                'Gagal Memuat Transaksi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF747685),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _loadTransactions,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    final transactions = _filteredTransactions;
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding =
        screenWidth > 600 ? (screenWidth - 600) / 2 + 16 : 16.0;

    return RefreshIndicator(
      onRefresh: _loadTransactions,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(horizontalPadding, 12, horizontalPadding, 32),
        children: [
          _buildSummaryBanner(
            count: _pendingTransactions.length,
            primaryColor: primaryColor,
            primaryContainer: primaryContainer,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
          ),
          const SizedBox(height: 20),
          _buildFilters(
            primaryColor: primaryColor,
            primaryContainer: primaryContainer,
            secondaryTextColor: secondaryTextColor,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Menunggu Persetujuan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF131B2E),
                  ),
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFBA1A1A),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (transactions.isEmpty)
            _buildEmptyState()
          else
            ...transactions.map(
              (transaction) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _buildTransactionCard(
                  transaction,
                  primaryColor: primaryColor,
                  primaryContainer: primaryContainer,
                  textColor: textColor,
                  secondaryTextColor: secondaryTextColor,
                ),
              ),
            ),
          const SizedBox(height: 8),
          _buildInformationBanner(),
        ],
      ),
    );
  }

  // =========================================================
  // SUMMARY BANNER
  // =========================================================

  Widget _buildSummaryBanner({
    required int count,
    required Color primaryColor,
    required Color primaryContainer,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E7FF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.assignment_late_outlined,
              color: Colors.white,
              size: 25,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count Permintaan Menunggu',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Konfirmasi transaksi Bank Mini SMKN 1 Bantul',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Pending',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // FILTER CHIPS
  // =========================================================

  Widget _buildFilters({
    required Color primaryColor,
    required Color primaryContainer,
    required Color secondaryTextColor,
  }) {
    final filters = [
      (
        filter: TransactionFilter.all,
        label: 'Semua',
      ),
      (
        filter: TransactionFilter.deposit,
        label: 'Setoran',
      ),
      (
        filter: TransactionFilter.withdrawal,
        label: 'Penarikan',
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((item) {
          final isSelected = _selectedFilter == item.filter;
          final count = _countByFilter(item.filter);

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: () {
                setState(() {
                  _selectedFilter = item.filter;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? primaryContainer
                      : const Color(0xFFEAEDFF),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : secondaryTextColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? primaryColor.withValues(alpha: 0.4)
                            : const Color(0xFFDAE2FD),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.white
                              : secondaryTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // =========================================================
  // TRANSACTION CARD
  // =========================================================

  Widget _buildTransactionCard(
    CustomerTransaction transaction, {
    required Color primaryColor,
    required Color primaryContainer,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    final isDeposit =
        transaction.transactionType == 'deposit';

    final transactionColor = isDeposit
        ? const Color(0xFF005137)
        : primaryColor;

    final transactionBackground = isDeposit
        ? const Color(0xFF85F8C4)
        : const Color(0xFFDAE2FD);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFDAD6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.circle,
                      size: 7,
                      color: Color(0xFFBA1A1A),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Menunggu Persetujuan',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF93000A),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.schedule_rounded,
                size: 15,
                color: Color(0xFF747685),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  _formatDate(transaction.transactionDate),
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 10,
                    color: secondaryTextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: transactionBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isDeposit
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded,
                  color: transactionColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'JENIS TRANSAKSI',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      transaction.transactionTypeLabel,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F3FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nominal Transaksi',
                  style: TextStyle(
                    fontSize: 11,
                    color: secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _formatCurrency(transaction.amount),
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                      color: transactionColor,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                _detailRow(
                  'ID Transaksi',
                  '#${transaction.id}',
                ),
                _detailRow(
                  'Waktu Pengajuan',
                  _formatDate(transaction.transactionDate),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: FilledButton(
              onPressed: () =>
                  _openTransactionDetail(transaction),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE2E7FF),
                foregroundColor: primaryContainer,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Lihat Detail',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // EMPTY STATE
  // =========================================================

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 36,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Color(0xFFEAEDFF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.task_alt_rounded,
              size: 34,
              color: Color(0xFF747685),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Tidak Ada Permintaan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF131B2E),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tidak ada transaksi yang menunggu persetujuan '
            'pada kategori ini.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: Color(0xFF747685),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // INFORMATION BANNER
  // =========================================================

  Widget _buildInformationBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAEDFF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 21,
            color: Color(0xFF003FB3),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Periksa jenis dan nominal transaksi sebelum '
              'melanjutkan. Pastikan PIN keamanan dimasukkan '
              'dengan benar.',
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: Color(0xFF434653),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================
// TRANSACTION DETAIL BOTTOM SHEET
// ===========================================================

class _TransactionDetailSheet extends StatefulWidget {
  const _TransactionDetailSheet({
    required this.transaction,
    required this.customerService,
    required this.formatCurrency,
    required this.formatDate,
  });

  final CustomerTransaction transaction;
  final CustomerService customerService;
  final String Function(int amount) formatCurrency;
  final String Function(DateTime date) formatDate;

  @override
  State<_TransactionDetailSheet> createState() =>
      _TransactionDetailSheetState();
}

class _TransactionDetailSheetState
    extends State<_TransactionDetailSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _pinController =
      TextEditingController();

  bool _isSubmitting = false;
  bool _obscurePin = true;
  String? _pinError;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  // =========================================================
  // CONFIRM TRANSACTION
  // =========================================================

  Future<void> _confirmTransaction() async {
    if (_isSubmitting) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _pinError = null;
    });

    try {
      final response =
          await widget.customerService.confirmTransaction(
        transactionId: widget.transaction.id,
        pin: _pinController.text,
      );

      if (!mounted) return;

      final responseData = response['data'];

      final Map<String, dynamic> result;

      if (responseData is Map<String, dynamic>) {
        result = responseData;
      } else {
        result = response;
      }

      final status = result['status']?.toString();

      if (status != 'approved') {
        throw Exception(
          'Server belum mengonfirmasi bahwa transaksi disetujui.',
        );
      }

      // Berikan nilai true kepada halaman induk.
      // Halaman induk akan memuat ulang daftar transaksi.
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
        _pinController.clear();
      });

      HapticFeedback.heavyImpact();

      final isBlocked = (error is CustomerApiException && error.isBlocked) ||
          error.toString().toLowerCase().contains('diblokir');

      final errorMsg = error is CustomerApiException
          ? error.message
          : error.toString().replaceFirst('Exception: ', '');

      if (isBlocked) {
        Navigator.of(context).pop(false);
        _showBlockedDialog(errorMsg);
        return;
      }

      setState(() {
        _pinError = errorMsg;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: const Color(0xFFBA1A1A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // =========================================================
  // BLOCKED DIALOG & FORGOT TRANSACTION PIN
  // =========================================================

  Future<void> _showBlockedDialog(String message) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          icon: Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Color(0xFFFFEBEE),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_person_rounded,
              size: 32,
              color: Color(0xFFBA1A1A),
            ),
          ),
          title: const Text(
            'Rekening Diblokir',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFFBA1A1A),
            ),
          ),
          content: Text(
            message.isNotEmpty
                ? message
                : 'PIN telah salah dimasukkan sebanyak 3 kali berturut-turut. '
                  'Demi keamanan dana Anda, rekening telah diblokir secara otomatis.\n\n'
                  'Silakan temui Petugas Admin atau Teller di Bank Mini Sekolah '
                  'untuk membuka blokir rekening.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: Color(0xFF434653),
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFBA1A1A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Mengerti',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showForgotPinHelp() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(
            Icons.lock_reset_rounded,
            size: 40,
            color: Color(0xFF003FB3),
          ),
          title: const Text(
            'Lupa PIN Transaksi?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: const Text(
            'Untuk menjaga keamanan rekening, silakan '
            'hubungi Admin Bank Mini Sekolah pada jam '
            'operasional untuk mendapatkan bantuan '
            'pengaturan ulang PIN transaksi.\n\n'
            'Jangan memberikan PIN atau password kepada '
            'orang lain.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.6,
              color: Color(0xFF747685),
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF002B81),
                foregroundColor: Colors.white,
              ),
              child: const Text('Mengerti'),
            ),
          ],
        );
      },
    );
  }

  // =========================================================
  // BUILD BOTTOM SHEET
  // =========================================================

  @override
Widget build(BuildContext context) {
  final transaction = widget.transaction;

  return Padding(
    padding: EdgeInsets.only(
      bottom: MediaQuery.of(context).viewInsets.bottom,
    ),
    child: Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD9DDE7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      'Konfirmasi Transaksi',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF131B2E),
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Periksa detail transaksi sebelum memasukkan PIN keamanan.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: Color(0xFF747685),
                      ),
                    ),

                    const SizedBox(height: 24),

                    _detailRow(
                      'ID Transaksi',
                      '#${transaction.id}',
                    ),

                    _detailRow(
                      'Jenis Transaksi',
                      transaction.transactionTypeLabel,
                    ),

                    _detailRow(
                      'Nominal',
                      widget.formatCurrency(transaction.amount),
                    ),

                    _detailRow(
                      'Waktu Pengajuan',
                      widget.formatDate(
                        transaction.transactionDate,
                      ),
                    ),

                    _detailRow(
                      'Status',
                      transaction.statusLabel,
                    ),

                    if (transaction.isPending) ...[
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 16),

                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'PIN Keamanan',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextButton(
                            onPressed: _isSubmitting
                                ? null
                                : _showForgotPinHelp,
                            child: const Text(
                              'Lupa PIN Transaksi?',
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      TextFormField(
                        controller: _pinController,
                        obscureText: _obscurePin,
                        enabled: !_isSubmitting,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        inputFormatters: [
                          FilteringTextInputFormatter
                              .digitsOnly,
                        ],
                        decoration: InputDecoration(
                          hintText: 'Masukkan 6 digit PIN',
                          counterText: '',
                          errorText: _pinError,
                          prefixIcon: const Icon(
                            Icons.lock_outline_rounded,
                          ),
                          suffixIcon: IconButton(
                            onPressed: _isSubmitting
                                ? null
                                : () {
                                    setState(() {
                                      _obscurePin =
                                          !_obscurePin;
                                    });
                                  },
                            icon: Icon(
                              _obscurePin
                                  ? Icons.visibility_outlined
                                  : Icons
                                      .visibility_off_outlined,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          final pin = value ?? '';

                          if (pin.isEmpty) {
                            return 'PIN wajib diisi.';
                          }

                          if (!RegExp(r'^\d{6}$')
                              .hasMatch(pin)) {
                            return 'PIN harus terdiri dari 6 digit.';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'Saldo akan diperbarui setelah transaksi berhasil diproses oleh server.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.5,
                          color: Color(0xFF747685),
                        ),
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton(
                          onPressed: _isSubmitting
                              ? null
                              : _confirmTransaction,
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Konfirmasi Transaksi',
                                ),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context)
                                .pop(false);
                          },
                          child: const Text('Tutup'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
  );
}


  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF747685),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF131B2E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
