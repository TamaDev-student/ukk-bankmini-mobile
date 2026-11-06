import 'package:customer_mobile/models/customer_transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('failed transaction maps its safe rejection reason and label', () {
    final transaction = CustomerTransaction.fromJson({
      'id': 42,
      'transaction_date': '2026-11-05T10:30:00.000000Z',
      'transaction_type': 'withdrawal',
      'amount': 50000,
      'status': 'failed',
      'rejection_reason': 'Transaksi tidak dapat diproses.',
    });

    expect(transaction.id, 42);
    expect(transaction.transactionTypeLabel, 'Penarikan Tunai');
    expect(transaction.statusLabel, 'Gagal');
    expect(transaction.rejectionReason, 'Transaksi tidak dapat diproses.');
  });

  test('known statuses use labels matching backend status', () {
    const cases = {
      'pending': 'Menunggu Konfirmasi',
      'approved': 'Berhasil',
      'rejected': 'Ditolak',
      'cancelled': 'Dibatalkan',
    };

    for (final entry in cases.entries) {
      final transaction = CustomerTransaction(
        id: 1,
        transactionDate: DateTime(2026, 11, 5),
        transactionType: 'deposit',
        amount: 10000,
        status: entry.key,
      );

      expect(transaction.statusLabel, entry.value);
      expect(transaction.isPending, entry.key == 'pending');
    }
  });
}
