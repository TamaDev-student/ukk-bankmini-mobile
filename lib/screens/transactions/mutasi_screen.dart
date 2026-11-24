import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/customer_account.dart';
import '../../models/customer_transaction.dart';
import '../../services/customer_service.dart';
import '../profile/profile_screen.dart';
import 'persetujuan_screen.dart';

const Color primaryBlue = Color(0xFF003FB3);
const Color darkBlue = Color(0xFF002B81);
const Color surfaceColor = Color(0xFFFAF8FF);
const Color lightBlue = Color(0xFFF2F3FF);
const Color borderColor = Color(0xFFC4C5D6);
const Color textColor = Color(0xFF131B2E);
const Color secondaryTextColor = Color(0xFF434653);
const Color successColor = Color(0xFF047857);
const Color dangerColor = Color(0xFFE11D48);

class MutasiScreen extends StatefulWidget {
  const MutasiScreen({super.key});

  @override
  State<MutasiScreen> createState() => _MutasiScreenState();
}

class _MutasiScreenState extends State<MutasiScreen> {
  final TextEditingController _searchController = TextEditingController();
  final CustomerService _customerService = CustomerService();

  int _selectedFilter = 0;
  int _selectedNavigationIndex = 1;

  bool _isBalanceVisible = true;
  bool _isLoading = true;
  bool _isDownloading = false;

  String? _errorMessage;
  String _selectedPeriod = 'Semua Periode';

  CustomerAccount? _account;
  List<CustomerTransaction> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _customerService.dispose();
    super.dispose();
  }

  // ============================================================
  // DATA
  // ============================================================

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait<dynamic>([
        _customerService.getAccount(),
        _customerService.getTransactions(),
      ]);

      if (!mounted) return;

      setState(() {
        _account = results[0] as CustomerAccount;
        _transactions = results[1] as List<CustomerTransaction>;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = _cleanErrorMessage(error);
        _isLoading = false;
      });
    }
  }

  String _cleanErrorMessage(Object error) {
    return error
        .toString()
        .replaceFirst('Exception: ', '')
        .replaceFirst('Bad state: ', '')
        .trim();
  }

  // ============================================================
  // FORMAT
  // ============================================================

  String _formatRupiah(int amount) {
    final digits = amount.abs().toString();
    final buffer = StringBuffer();

    for (var i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);

      final remaining = digits.length - i - 1;

      if (remaining > 0 && remaining % 3 == 0) {
        buffer.write('.');
      }
    }

    return 'Rp $buffer';
  }

  String _formatTransactionAmount(
    int amount, {
    required bool isCredit,
  }) {
    final prefix = isCredit ? '+ ' : '- ';
    return '$prefix${_formatRupiah(amount)}';
  }

  String _formatDate(DateTime date) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    final local = date.toLocal();

    return '${local.day} ${months[local.month - 1]} ${local.year}';
  }

  String _formatDateForPicker(DateTime date) {
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

    return '${date.day.toString().padLeft(2, '0')} '
        '${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(DateTime date) {
    final local = date.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  DateTime _dateOnly(DateTime date) {
    final local = date.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  String _dateGroupKey(DateTime date) {
    final local = date.toLocal();

    return '${local.year}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }

  // ============================================================
  // FILTER TRANSAKSI
  // ============================================================

  bool _matchesPeriod(DateTime date) {
    final now = DateTime.now();
    final local = date.toLocal();

    switch (_selectedPeriod) {
      case 'Bulan Ini':
        return local.year == now.year && local.month == now.month;

      case '3 Bulan Terakhir':
        final start = DateTime(now.year, now.month - 2, 1);
        final end = DateTime(now.year, now.month + 1, 1);

        return !local.isBefore(start) && local.isBefore(end);

      case 'Tahun Ini':
        return local.year == now.year;

      default:
        return true;
    }
  }

  List<CustomerTransaction> get _filteredTransactions {
    final query = _searchController.text.trim().toLowerCase();

    final filtered = _transactions.where((transaction) {
      final isDeposit = transaction.transactionType == 'deposit';
      final isWithdrawal = transaction.transactionType == 'withdrawal';

      final matchesType = switch (_selectedFilter) {
        1 => isDeposit,
        2 => isWithdrawal,
        _ => true,
      };

      final searchableText = [
        transaction.id.toString(),
        transaction.transactionTypeLabel,
        transaction.statusLabel,
        transaction.amount.toString(),
        _formatRupiah(transaction.amount),
        _formatDate(transaction.transactionDate),
        _formatTime(transaction.transactionDate),
      ].join(' ').toLowerCase();

      return matchesType &&
          searchableText.contains(query) &&
          _matchesPeriod(transaction.transactionDate);
    }).toList();

    filtered.sort(
      (a, b) => b.transactionDate.compareTo(a.transactionDate),
    );

    return filtered;
  }

  Map<String, List<CustomerTransaction>> get _groupedTransactions {
    final groups = <String, List<CustomerTransaction>>{};

    for (final transaction in _filteredTransactions) {
      final key = _dateGroupKey(transaction.transactionDate);

      groups.putIfAbsent(key, () => []);
      groups[key]!.add(transaction);
    }

    return groups;
  }

  // ============================================================
  // NOTIFIKASI DAN REKENING
  // ============================================================

  void _showMessage(String message, {Color? backgroundColor}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _copyAccountNumber() async {
    final accountNumber = _account?.accountNumber;

    if (accountNumber == null || accountNumber.isEmpty) {
      _showMessage('Nomor rekening belum tersedia.');
      return;
    }

    await Clipboard.setData(
      ClipboardData(text: accountNumber),
    );

    if (!mounted) return;

    _showMessage(
      'Nomor rekening berhasil disalin.',
      backgroundColor: successColor,
    );
  }

  void _onNavigationTap(int index) {
    if (index == 1) {
      setState(() {
        _selectedNavigationIndex = 1;
      });
      return;
    }

    if (index == 0) {
      Navigator.of(context).pop();
      return;
    }

    if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const PersetujuanScreen(),
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

  void _resetFilters() {
    setState(() {
      _selectedFilter = 0;
      _selectedPeriod = 'Semua Periode';
      _searchController.clear();
    });
  }

  // ============================================================
  // FILTER PERIODE RIWAYAT
  // ============================================================

  void _showPeriodPicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Periode Transaksi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 16),
                _periodOption('Semua Periode'),
                _periodOption('Bulan Ini'),
                _periodOption('3 Bulan Terakhir'),
                _periodOption('Tahun Ini'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _periodOption(String title) {
    final isSelected = title == _selectedPeriod;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(
        Icons.calendar_today_rounded,
        color: primaryBlue,
      ),
      title: Text(title),
      trailing: isSelected
          ? const Icon(
              Icons.check_circle,
              color: primaryBlue,
            )
          : null,
      onTap: () {
        Navigator.pop(context);

        setState(() {
          _selectedPeriod = title;
        });
      },
    );
  }

  // ============================================================
  // STATUS TRANSAKSI
  // ============================================================

  ({Color bg, Color text, String label}) _statusStyle(
    CustomerTransaction transaction,
  ) {
    switch (transaction.status.toLowerCase()) {
      case 'approved':
        return (
          bg: const Color(0xFFD1FAE5),
          text: successColor,
          label: 'Berhasil',
        );

      case 'pending':
        return (
          bg: const Color(0xFFFEF3C7),
          text: const Color(0xFFB45309),
          label: 'Menunggu Konfirmasi',
        );

      case 'rejected':
        return (
          bg: const Color(0xFFFFE4E6),
          text: dangerColor,
          label: 'Ditolak',
        );

      case 'failed':
        return (
          bg: const Color(0xFFFFE4E6),
          text: dangerColor,
          label: 'Gagal',
        );

      case 'cancelled':
        return (
          bg: const Color(0xFFFEE2E2),
          text: const Color(0xFFB91C1C),
          label: 'Dibatalkan',
        );

      default:
        return (
          bg: const Color(0xFFF3F4F6),
          text: secondaryTextColor,
          label: transaction.statusLabel,
        );
    }
  }

  // ============================================================
  // DETAIL TRANSAKSI
  // ============================================================

  void _showTransactionDetail(CustomerTransaction transaction) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _TransactionDetailSheet(
          transaction: transaction,
          customerService: _customerService,
          formatDate: _formatDate,
          formatTime: _formatTime,
          formatRupiah: _formatRupiah,
          formatTransactionAmount: _formatTransactionAmount,
          statusStyle: _statusStyle,
          showMessage: _showMessage,
          onTransactionUpdated: _loadData,
        );
      },
    );
  }


  // ============================================================
  // DOWNLOAD PDF: PILIH PERIODE
  // ============================================================

  void _showDownloadStatementSheet() {
    if (_isDownloading) return;

    int selectedOption = 0;
    DateTime? customStart;
    DateTime? customEnd;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (innerContext, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  MediaQuery.of(innerContext).viewInsets.bottom + 20,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: borderColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Row(
                        children: [
                          Icon(
                            Icons.download_rounded,
                            color: primaryBlue,
                            size: 22,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Unduh Mutasi Rekening',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Unduh laporan transaksi rekeningmu dalam format PDF.',
                        style: TextStyle(
                          fontSize: 12,
                          color: secondaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 18),
                      ..._buildPeriodOptions(
                        selectedOption,
                        (value) {
                          setSheetState(() {
                            selectedOption = value;
                          });
                        },
                      ),
                      if (selectedOption == 4) ...[
                        const SizedBox(height: 12),
                        _buildCustomDateRange(
                          customStart: customStart,
                          customEnd: customEnd,
                          onChange: (start, end) {
                            setSheetState(() {
                              customStart = start;
                              customEnd = end;
                            });
                          },
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _isDownloading
                              ? null
                              : () {
                                  final range = _resolveDateRange(
                                    selectedOption,
                                    customStart,
                                    customEnd,
                                  );

                                  if (range == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Periksa kembali tanggal awal dan akhir.',
                                        ),
                                        backgroundColor: dangerColor,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                    return;
                                  }

                                  Navigator.pop(sheetContext);

                                  _executeDownload(
                                    range.$1,
                                    range.$2,
                                  );
                                },
                          icon: const Icon(
                            Icons.picture_as_pdf_rounded,
                            size: 20,
                          ),
                          label: const Text(
                            'Unduh PDF',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                primaryBlue.withValues(alpha: 0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<Widget> _buildPeriodOptions(
    int selectedOption,
    ValueChanged<int> onChanged,
  ) {
    const options = [
      'Bulan Ini',
      'Bulan Lalu',
      '3 Bulan Terakhir',
      'Tahun Ini',
      'Rentang Tanggal Khusus',
    ];

    return List.generate(options.length, (index) {
      final isSelected = selectedOption == index;

      return Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: InkWell(
          onTap: () => onChanged(index),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? primaryBlue.withValues(alpha: 0.08)
                  : Colors.transparent,
              border: Border.all(
                color: isSelected
                    ? primaryBlue
                    : borderColor.withValues(alpha: 0.5),
                width: isSelected ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: isSelected
                      ? primaryBlue
                      : secondaryTextColor,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    options[index],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isSelected
                          ? primaryBlue
                          : textColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  // ============================================================
  // DOWNLOAD PDF: RENTANG TANGGAL KHUSUS
  // ============================================================

  Widget _buildCustomDateRange({
    required DateTime? customStart,
    required DateTime? customEnd,
    required void Function(DateTime? start, DateTime? end) onChange,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: lightBlue,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: borderColor.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pilih rentang tanggal:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: secondaryTextColor,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildDatePickerButton(
                  label: 'Dari',
                  value: customStart == null
                      ? 'Pilih'
                      : _formatDateForPicker(customStart),
                  onTap: () async {
                    final now = DateTime.now();
                    final today = _dateOnly(now);

                    final initialDate = customStart == null
                        ? today
                        : _dateOnly(customStart);

                    final picked = await showDatePicker(
                      context: context,
                      initialDate: initialDate.isAfter(today)
                          ? today
                          : initialDate,
                      firstDate: DateTime(2020),
                      lastDate: today,
                    );

                    if (picked == null) return;

                    final start = _dateOnly(picked);
                    final end = customEnd == null
                        ? null
                        : _dateOnly(customEnd);

                    onChange(
                      start,
                      end != null && end.isBefore(start) ? null : end,
                    );
                  },
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.arrow_forward,
                  size: 16,
                  color: secondaryTextColor,
                ),
              ),
              Expanded(
                child: _buildDatePickerButton(
                  label: 'Sampai',
                  value: customEnd == null
                      ? 'Pilih'
                      : _formatDateForPicker(customEnd),
                  onTap: () async {
                    final now = DateTime.now();
                    final today = _dateOnly(now);

                    final start = customStart == null
                        ? DateTime(2020)
                        : _dateOnly(customStart);

                    final initial = customEnd == null
                        ? today
                        : _dateOnly(customEnd);

                    final safeInitial = initial.isBefore(start)
                        ? start
                        : initial.isAfter(today)
                            ? today
                            : initial;

                    if (start.isAfter(today)) {
                      _showMessage('Tanggal awal tidak boleh di masa depan.');
                      return;
                    }

                    final picked = await showDatePicker(
                      context: context,
                      initialDate: safeInitial,
                      firstDate: start,
                      lastDate: today,
                    );

                    if (picked == null) return;

                    onChange(
                      customStart,
                      _dateOnly(picked),
                    );
                  },
                ),
              ),
            ],
          ),
          if (customStart != null && customEnd != null) ...[
            const SizedBox(height: 10),
            Text(
              'Periode: ${_formatDateForPicker(customStart)} – '
              '${_formatDateForPicker(customEnd)}',
              style: const TextStyle(
                fontSize: 11,
                color: secondaryTextColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDatePickerButton({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: secondaryTextColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 13,
                  color: primaryBlue,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DOWNLOAD PDF: VALIDASI PERIODE
  // ============================================================

  (DateTime, DateTime)? _resolveDateRange(
    int option,
    DateTime? customStart,
    DateTime? customEnd,
  ) {
    final now = DateTime.now();
    final today = _dateOnly(now);

    switch (option) {
      case 0:
        return (
          DateTime(today.year, today.month, 1),
          today,
        );

      case 1:
        final start = DateTime(today.year, today.month - 1, 1);
        final end = DateTime(today.year, today.month, 0);

        return (start, end);

      case 2:
        final start = DateTime(today.year, today.month - 2, 1);

        return (start, today);

      case 3:
        return (
          DateTime(today.year, 1, 1),
          today,
        );

      case 4:
        if (customStart == null || customEnd == null) {
          return null;
        }

        final start = _dateOnly(customStart);
        final end = _dateOnly(customEnd);

        if (start.isAfter(end) || end.isAfter(today)) {
          return null;
        }

        return (start, end);

      default:
        return null;
    }
  }

  // ============================================================
  // DOWNLOAD PDF: EKSEKUSI
  // ============================================================

  Future<void> _executeDownload(
    DateTime startDate,
    DateTime endDate,
  ) async {
    if (_isDownloading || !mounted) return;

    final start = _dateOnly(startDate);
    final end = _dateOnly(endDate);
    final today = _dateOnly(DateTime.now());

    if (start.isAfter(end) || end.isAfter(today)) {
      _showMessage(
        'Rentang tanggal laporan tidak valid.',
        backgroundColor: dangerColor,
      );
      return;
    }

    setState(() {
      _isDownloading = true;
    });

    try {
      final bytes = await _customerService.downloadAccountStatement(
        startDate: start,
        endDate: end,
      );

      if (!mounted) return;

      if (bytes.isEmpty) {
        throw Exception('Server tidak mengembalikan file PDF.');
      }

      // Simpan PDF pada direktori dokumen privat aplikasi.
      final directory = await getApplicationDocumentsDirectory();

      final accountNumber = (_account?.accountNumber ?? 'unknown')
          .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');

      final startString = DateFormat('yyyy-MM-dd').format(start);
      final endString = DateFormat('yyyy-MM-dd').format(end);

      final filename =
          'Mutasi_${accountNumber}_${startString}_$endString.pdf';

      final file = File('${directory.path}/$filename');

      await file.writeAsBytes(bytes, flush: true);

      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Text('Laporan mutasi berhasil disimpan.'),
            backgroundColor: successColor,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'Buka PDF',
              textColor: Colors.white,
              onPressed: () {
                _openStatementFile(file);
              },
            ),
          ),
        );
    } on CustomerApiException catch (error) {
      if (!mounted) return;

      final String message;

      switch (error.statusCode) {
        case 401:
          message = 'Sesi login berakhir. Silakan login kembali.';
          break;

        case 403:
          message = 'Akses laporan mutasi tidak diizinkan.';
          break;

        case 422:
          message = error.message;
          break;

        default:
          message = 'Gagal mengunduh laporan. Silakan coba kembali.';
      }

      _showMessage(
        message,
        backgroundColor: dangerColor,
      );
    } on SocketException {
      if (!mounted) return;

      _showMessage(
        'Koneksi internet bermasalah. Silakan coba kembali.',
        backgroundColor: dangerColor,
      );
    } catch (error) {
      if (!mounted) return;

      debugPrint('Unduh laporan mutasi gagal: ${_cleanErrorMessage(error)}');

      _showMessage(
        'Gagal mengunduh atau menyimpan laporan PDF.',
        backgroundColor: dangerColor,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  Future<void> _openStatementFile(File file) async {
    if (!await file.exists()) {
      _showMessage(
        'File laporan tidak ditemukan.',
        backgroundColor: dangerColor,
      );
      return;
    }

    try {
      final result = await OpenFilex.open(file.path);

      if (!mounted) return;

      if (result.type != ResultType.done) {
        _showMessage(
          'PDF tersimpan, tetapi tidak ada aplikasi yang dapat membukanya.',
          backgroundColor: dangerColor,
        );
      }
    } catch (_) {
      if (!mounted) return;

      _showMessage(
        'PDF tersimpan, tetapi gagal dibuka.',
        backgroundColor: dangerColor,
      );
    }
  }

  // ============================================================
  // APP BAR
  // ============================================================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: surfaceColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 20,
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mutasi Rekening',
            style: TextStyle(
              color: textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: 3),
          Text(
            'Catatan transaksi rekening siswa SMKN 1 Bantul',
            style: TextStyle(
              color: secondaryTextColor,
              fontSize: 11,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
      actions: [
        Tooltip(
          message: 'Unduh Mutasi Rekening',
          child: IconButton(
            onPressed: _isDownloading
                ? null
                : _showDownloadStatementSheet,
            icon: _isDownloading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: primaryBlue,
                    ),
                  )
                : const Icon(
                    Icons.download_rounded,
                    color: primaryBlue,
                    size: 24,
                  ),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ============================================================
  // BUILD UTAMA
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: surfaceColor,
        appBar: _buildAppBar(),
        body: const Center(
          child: CircularProgressIndicator(
            color: primaryBlue,
          ),
        ),
        bottomNavigationBar: _buildBottomNavigation(),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: surfaceColor,
        appBar: _buildAppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: dangerColor,
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba Lagi'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryBlue,
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _buildBottomNavigation(),
      );
    }

    final transactions = _filteredTransactions;
    final groupedTransactions = _groupedTransactions;

    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: _buildAppBar(),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: primaryBlue,
          child: CustomScrollView(
            keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior.onDrag,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Ringkasan saldo rekening.
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                  child: _buildBalanceCard(),
                ),
              ),

              // Filter tipe transaksi.
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _filterButton('Semua', 0),
                        const SizedBox(width: 8),
                        _filterButton(
                          'Setoran',
                          1,
                          dotColor: successColor,
                        ),
                        const SizedBox(width: 8),
                        _filterButton(
                          'Penarikan',
                          2,
                          dotColor: dangerColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Pencarian dan filter periode.
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: _buildSearchAndFilters(),
                ),
              ),

              // Daftar transaksi.
              if (transactions.isEmpty)
                SliverToBoxAdapter(
                  child: _buildEmptyState(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final dateKey =
                            groupedTransactions.keys.elementAt(index);

                        final items = groupedTransactions[dateKey]!;

                        return _buildTransactionGroup(
                          dateKey,
                          items,
                        );
                      },
                      childCount: groupedTransactions.length,
                    ),
                  ),
                ),

              // Catatan resmi.
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: lightBlue.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE2E7FF),
                      ),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.verified_user_outlined,
                          size: 19,
                          color: primaryBlue,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Catatan transaksi resmi Bank Mini SMKN 1 Bantul.',
                            style: TextStyle(
                              fontSize: 11,
                              height: 1.5,
                              color: secondaryTextColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  // ============================================================
  // KARTU SALDO
  // ============================================================

  Widget _buildBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE2E7FF),
        ),
        boxShadow: [
          BoxShadow(
            color: darkBlue.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: lightBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: primaryBlue,
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SALDO REKENING',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                    color: secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isBalanceVisible
                      ? _formatRupiah(_account?.balance ?? 0)
                      : 'Rp •••••••',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'No. Rekening',
                  style: TextStyle(
                    fontSize: 10,
                    color: secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 5),
                InkWell(
                  onTap: _copyAccountNumber,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: lightBlue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            _account?.accountNumber ?? '-',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: primaryBlue,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.copy_rounded,
                          size: 13,
                          color: primaryBlue,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 2),
          IconButton(
            tooltip: _isBalanceVisible
                ? 'Sembunyikan saldo'
                : 'Tampilkan saldo',
            onPressed: () {
              setState(() {
                _isBalanceVisible = !_isBalanceVisible;
              });
            },
            visualDensity: VisualDensity.compact,
            icon: Icon(
              _isBalanceVisible
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 18,
              color: secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PENCARIAN DAN FILTER
  // ============================================================

  Widget _buildSearchAndFilters() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(
              fontSize: 12,
              color: textColor,
            ),
            decoration: InputDecoration(
              hintText: 'Cari transaksi...',
              hintStyle: const TextStyle(
                color: secondaryTextColor,
                fontSize: 12,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                size: 20,
                color: secondaryTextColor,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                        });
                      },
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 17,
                      ),
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: borderColor,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFFE2E7FF),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: primaryBlue,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: _showPeriodPicker,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 13,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE2E7FF),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 15,
                  color: primaryBlue,
                ),
                const SizedBox(width: 5),
                Text(
                  _selectedPeriod,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(width: 3),
                const Icon(
                  Icons.expand_more_rounded,
                  size: 16,
                  color: secondaryTextColor,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
        IconButton(
          tooltip: 'Muat ulang data',
          onPressed: _loadData,
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: secondaryTextColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(
                color: Color(0xFFE2E7FF),
              ),
            ),
          ),
          icon: const Icon(
            Icons.refresh_rounded,
            size: 19,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // TOMBOL FILTER JENIS
  // ============================================================

  Widget _filterButton(
    String label,
    int index, {
    Color? dotColor,
  }) {
    final isSelected = _selectedFilter == index;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = index;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected ? primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? primaryBlue
                : const Color(0xFFE2E7FF),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryBlue.withValues(alpha: 0.10),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dotColor != null) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : secondaryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // GRUP TRANSAKSI
  // ============================================================

  Widget _buildTransactionGroup(
    String dateKey,
    List<CustomerTransaction> transactions,
  ) {
    final displayDate = transactions.isNotEmpty
        ? _formatDate(transactions.first.transactionDate)
        : dateKey;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                displayDate.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: secondaryTextColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFDAE2FD),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${transactions.length} Transaksi',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: secondaryTextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                color: const Color(0xFFE2E7FF),
              ),
            ),
            child: Column(
              children: [
                for (var i = 0; i < transactions.length; i++) ...[
                  if (i > 0)
                    const Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: Color(0xFFE2E7FF),
                    ),
                  _buildTransactionCard(transactions[i]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // KARTU TRANSAKSI
  // ============================================================

  Widget _buildTransactionCard(
    CustomerTransaction transaction,
  ) {
    final isCredit = transaction.transactionType == 'deposit';
    final isCancelled =
        transaction.status.toLowerCase() == 'cancelled';

    final status = _statusStyle(transaction);

    final transactionColor = isCancelled
        ? const Color(0xFFDC2626)
        : isCredit
            ? successColor
            : dangerColor;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _showTransactionDetail(transaction),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: isCancelled
                      ? const Color(0xFFFEE2E2)
                      : isCredit
                          ? const Color(0xFFECFDF5)
                          : const Color(0xFFFFF1F2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCancelled
                      ? Icons.cancel_outlined
                      : isCredit
                          ? Icons.arrow_downward_rounded
                          : Icons.arrow_upward_rounded,
                  color: transactionColor,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.transactionTypeLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${_formatDate(transaction.transactionDate)} • '
                      '${_formatTime(transaction.transactionDate)} WIB',
                      style: const TextStyle(
                        fontSize: 10,
                        color: secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: status.bg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        status.label,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: status.text,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  isCancelled
                      ? 'Dibatalkan\n${_formatRupiah(transaction.amount)}'
                      : _formatTransactionAmount(
                          transaction.amount,
                          isCredit: isCredit,
                        ),
                  textAlign: TextAlign.end,
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: transactionColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // KONDISI KOSONG
  // ============================================================

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 22,
          vertical: 30,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFE2E7FF),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: lightBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                size: 32,
                color: secondaryTextColor,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tidak Ada Mutasi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Belum ada transaksi yang sesuai dengan filter.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                height: 1.5,
                color: secondaryTextColor,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _resetFilters,
              style: FilledButton.styleFrom(
                backgroundColor: primaryBlue,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Reset Filter Transaksi',
                style: TextStyle(fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // NAVIGASI BAWAH
  // ============================================================

  Widget _buildBottomNavigation() {
    const destinations = [
      (label: 'Beranda', icon: Icons.home_outlined),
      (label: 'Mutasi', icon: Icons.receipt_long_rounded),
      (label: 'Persetujuan', icon: Icons.fact_check_outlined),
      (label: 'Profil', icon: Icons.person_outline_rounded),
    ];

    final hasPending = _transactions.any((transaction) {
      return transaction.isPending;
    });

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
            children: List.generate(destinations.length, (index) {
              final destination = destinations[index];
              final isSelected =
                  _selectedNavigationIndex == index;

              return Expanded(
                child: InkWell(
                  onTap: () => _onNavigationTap(index),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            destination.icon,
                            size: 22,
                            color: isSelected
                                ? primaryBlue
                                : secondaryTextColor,
                          ),
                          if (index == 2 && hasPending)
                            Positioned(
                              top: -2,
                              right: -5,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: dangerColor,
                                  shape: BoxShape.circle,
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
                              ? primaryBlue
                              : secondaryTextColor,
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
}

// ============================================================
// WIDGET DETAIL TRANSAKSI
// Dipisahkan dari MutasiScreen agar state pembatalan terisolasi.
// ============================================================

class _TransactionDetailSheet extends StatefulWidget {
  const _TransactionDetailSheet({
    required this.transaction,
    required this.customerService,
    required this.formatDate,
    required this.formatTime,
    required this.formatRupiah,
    required this.formatTransactionAmount,
    required this.statusStyle,
    required this.showMessage,
    required this.onTransactionUpdated,
  });

  final CustomerTransaction transaction;
  final CustomerService customerService;

  final String Function(DateTime) formatDate;
  final String Function(DateTime) formatTime;
  final String Function(int) formatRupiah;

  final String Function(
    int, {
    required bool isCredit,
  }) formatTransactionAmount;

  final ({Color bg, Color text, String label}) Function(
    CustomerTransaction,
  ) statusStyle;

  final void Function(
    String message, {
    Color? backgroundColor,
  }) showMessage;

  final Future<void> Function() onTransactionUpdated;

  @override
  State<_TransactionDetailSheet> createState() =>
      _TransactionDetailSheetState();
}

class _TransactionDetailSheetState
    extends State<_TransactionDetailSheet> {
  late Future<CustomerTransaction> _detailFuture;

  CustomerTransaction? _refreshedTransaction;
  bool _isCancelling = false;

  CustomerTransaction get _currentTransaction {
    return _refreshedTransaction ?? widget.transaction;
  }

  @override
  void initState() {
    super.initState();

    _detailFuture = widget.customerService.getTransactionDetail(
      widget.transaction.id,
    );
  }


  Future<void> _cancelTransaction() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Batalkan Transaksi?'),
          content: const Text(
            'Apakah kamu yakin ingin membatalkan transaksi ini? '
            'Pembatalan hanya dapat dilakukan jika transaksi masih '
            'menunggu proses sesuai aturan sistem.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Tidak'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(
                backgroundColor: dangerColor,
              ),
              child: const Text('Ya, Batalkan'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isCancelling = true;
    });

    try {
      final cancelled = await widget.customerService.cancelTransaction(
        _currentTransaction.id,
      );

      if (!mounted) return;

      setState(() {
        _refreshedTransaction = cancelled;
        _detailFuture = Future.value(cancelled);
        _isCancelling = false;
      });

      widget.showMessage(
        'Transaksi berhasil dibatalkan.',
        backgroundColor: successColor,
      );

      await widget.onTransactionUpdated();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isCancelling = false;
      });

      widget.showMessage(
        error
            .toString()
            .replaceFirst('Exception: ', ''),
        backgroundColor: dangerColor,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: FutureBuilder<CustomerTransaction>(
                future: _detailFuture,
                initialData: widget.transaction,
                builder: (context, snapshot) {
                  final transaction =
                      _refreshedTransaction ??
                      snapshot.data ??
                      widget.transaction;

                  final isCredit =
                      transaction.transactionType == 'deposit';

                  final status = widget.statusStyle(transaction);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 5,
                          decoration: BoxDecoration(
                            color: borderColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'TANDA TERIMA KAS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                              color: secondaryTextColor,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: status.bg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status.label.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: status.text,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (snapshot.connectionState ==
                          ConnectionState.waiting)
                        const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: LinearProgressIndicator(
                            minHeight: 2,
                            color: primaryBlue,
                          ),
                        )
                      else if (snapshot.hasError)
                        const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: Text(
                            'Status terbaru tidak dapat dimuat. '
                            'Data riwayat tetap ditampilkan.',
                            style: TextStyle(
                              fontSize: 12,
                              color: secondaryTextColor,
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: lightBlue,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Nominal Transaksi',
                              style: TextStyle(
                                fontSize: 12,
                                color: secondaryTextColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.formatTransactionAmount(
                                transaction.amount,
                                isCredit: isCredit,
                              ),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: isCredit
                                    ? successColor
                                    : dangerColor,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              transaction.transactionTypeLabel,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: primaryBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      _detailRow(
                        'ID Transaksi',
                        '#${transaction.id}',
                      ),
                      _detailRow(
                        'Jenis Transaksi',
                        transaction.transactionTypeLabel,
                      ),
                      _detailRow(
                        'Status',
                        status.label,
                      ),
                      _detailRow(
                        'Tanggal',
                        widget.formatDate(transaction.transactionDate),
                      ),
                      _detailRow(
                        'Waktu Transaksi',
                        '${widget.formatTime(transaction.transactionDate)} WIB',
                        isLast: transaction.rejectionReason == null,
                      ),
                      if (transaction.rejectionReason != null)
                        _detailRow(
                          'Alasan',
                          transaction.rejectionReason!,
                          isLast: true,
                        ),
                      const SizedBox(height: 22),
                      if (transaction.isPending &&
                          !snapshot.hasError)
                        FilledButton(
                          onPressed: _isCancelling
                              ? null
                              : _cancelTransaction,
                          style: FilledButton.styleFrom(
                            backgroundColor: dangerColor,
                            padding: const EdgeInsets.symmetric(
                              vertical: 15,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isCancelling
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Batalkan Transaksi'),
                        ),
                      const SizedBox(height: 10),
                      FilledButton(
                        onPressed: () => Navigator.pop(context),
                        style: FilledButton.styleFrom(
                          backgroundColor: primaryBlue,
                          padding: const EdgeInsets.symmetric(
                            vertical: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Tutup Rincian'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(
    String label,
    String value, {
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(
                  color: Color(0xFFE2E7FF),
                ),
              ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: secondaryTextColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 11,
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}