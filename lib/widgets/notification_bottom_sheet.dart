import 'package:flutter/material.dart';

import '../models/customer_transaction.dart';

class NotificationBottomSheet extends StatelessWidget {
  const NotificationBottomSheet({
    super.key,
    required this.pendingTransactions,
    required this.recentTransactions,
    required this.onOpenPersetujuan,
    required this.formatRupiah,
    required this.formatDate,
    required this.formatTime,
  });

  final List<CustomerTransaction> pendingTransactions;
  final List<CustomerTransaction> recentTransactions;
  final VoidCallback onOpenPersetujuan;
  final String Function(int) formatRupiah;
  final String Function(DateTime) formatDate;
  final String Function(DateTime) formatTime;

  static void show(
    BuildContext context, {
    required List<CustomerTransaction> pendingTransactions,
    required List<CustomerTransaction> recentTransactions,
    required VoidCallback onOpenPersetujuan,
    required String Function(int) formatRupiah,
    required String Function(DateTime) formatDate,
    required String Function(DateTime) formatTime,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NotificationBottomSheet(
        pendingTransactions: pendingTransactions,
        recentTransactions: recentTransactions,
        onOpenPersetujuan: onOpenPersetujuan,
        formatRupiah: formatRupiah,
        formatDate: formatDate,
        formatTime: formatTime,
      ),
    );
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
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E7FF),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: pendingTransactions.isNotEmpty
                              ? const Color(0xFFFEF3C7)
                              : const Color(0xFFEDF3FF),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          pendingTransactions.isNotEmpty
                              ? Icons.notifications_active_rounded
                              : Icons.notifications_rounded,
                          color: pendingTransactions.isNotEmpty
                              ? const Color(0xFFD97706)
                              : const Color(0xFF003FB3),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Pusat Notifikasi',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF131B2E),
                        ),
                      ),
                      if (pendingTransactions.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFFDE68A),
                            ),
                          ),
                          child: Text(
                            '${pendingTransactions.length} Menunggu',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFB45309),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, size: 20),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF0F1F5)),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                children: [
                  if (pendingTransactions.isNotEmpty) ...[
                    const Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 15,
                          color: Color(0xFFB45309),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'MEMBUTUHKAN PERSETUJUAN ANDA',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    for (final txn in pendingTransactions)
                      _buildPendingNotificationCard(context, txn),
                    const SizedBox(height: 18),
                  ],
                  if (recentTransactions.isNotEmpty) ...[
                    const Text(
                      'AKTIVITAS TRANSAKSI TERAKHIR',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        color: Color(0xFF9298A7),
                      ),
                    ),
                    const SizedBox(height: 9),
                    for (final txn in recentTransactions)
                      _buildRecentNotificationCard(txn),
                  ],
                  if (pendingTransactions.isEmpty && recentTransactions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 50),
                      child: Column(
                        children: const [
                          Icon(
                            Icons.notifications_off_outlined,
                            size: 48,
                            color: Color(0xFF9298A7),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Tidak Ada Notifikasi',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF202536),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Belum ada permintaan transaksi atau aktivitas baru.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9298A7),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);
  }

  Widget _buildPendingNotificationCard(
    BuildContext context,
    CustomerTransaction txn,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFDE68A),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD97706).withValues(alpha: 0.05),
            blurRadius: 10,
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
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_clock_rounded,
                  color: Color(0xFFD97706),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Persetujuan ${txn.transactionTypeLabel}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF92400E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${formatDate(txn.transactionDate)} • ${formatTime(txn.transactionDate)} WIB',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDE68A),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'PIN Diperlukan',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF92400E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Petugas Teller mengajukan penarikan tunai sebesar ${formatRupiah(txn.amount)}. '
            'Diperlukan konfirmasi PIN transaksi Anda untuk menyetujui transaksi ini.',
            style: const TextStyle(
              fontSize: 11,
              height: 1.4,
              color: Color(0xFF78350F),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
                onOpenPersetujuan();
              },
              icon: const Icon(Icons.key_rounded, size: 16),
              label: const Text(
                'Konfirmasi & Masukkan PIN',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFD97706),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentNotificationCard(CustomerTransaction txn) {
    final isDeposit = txn.transactionType == 'deposit';
    final isApproved = txn.status == 'approved';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFEEF0F5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isApproved
                  ? const Color(0xFFE8F8F0)
                  : const Color(0xFFFFEEF0),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isApproved
                  ? Icons.check_circle_outline_rounded
                  : Icons.cancel_outlined,
              color: isApproved
                  ? const Color(0xFF16865B)
                  : const Color(0xFFD94A5B),
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${txn.transactionTypeLabel} ${txn.statusLabel}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF202536),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${formatDate(txn.transactionDate)} • ${formatTime(txn.transactionDate)} WIB',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF9298A7),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isDeposit ? '+' : '-'} ${formatRupiah(txn.amount)}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isApproved && isDeposit
                  ? const Color(0xFF16865B)
                  : const Color(0xFF202536),
            ),
          ),
        ],
      ),
    );
  }
}
