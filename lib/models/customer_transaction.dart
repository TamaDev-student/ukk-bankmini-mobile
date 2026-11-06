class CustomerTransaction {
  const CustomerTransaction({
    required this.id,
    required this.transactionDate,
    required this.transactionType,
    required this.amount,
    required this.status,
    this.rejectionReason,
  });

  final int id;
  final DateTime transactionDate;
  final String transactionType;
  final int amount;
  final String status;
  final String? rejectionReason;

  factory CustomerTransaction.fromJson(Map<String, dynamic> json) {
    final transactionDate = json['transaction_date'];
    final transactionType = json['transaction_type'];
    final status = json['status'];

    if (transactionDate is! String ||
        transactionType is! String ||
        status is! String) {
      throw const FormatException('Data transaksi tidak valid.');
    }

    return CustomerTransaction(
      id: _parseInteger(json['id'], 'ID transaksi'),
      transactionDate: DateTime.parse(transactionDate),
      transactionType: transactionType,
      amount: _parseInteger(json['amount'], 'Nominal transaksi'),
      status: status,
      rejectionReason: _parseNullableString(json['rejection_reason']),
    );
  }

  static int _parseInteger(dynamic value, String fieldName) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }

    throw FormatException('$fieldName tidak valid.');
  }

  static String? _parseNullableString(dynamic value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String get transactionTypeLabel {
    switch (transactionType) {
      case 'deposit':
        return 'Setoran Tunai';
      case 'withdrawal':
        return 'Penarikan Tunai';
      default:
        return 'Transaksi';
    }
  }

  String get statusLabel {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Menunggu Konfirmasi';
      case 'approved':
        return 'Berhasil';
      case 'rejected':
        return 'Ditolak';
      case 'failed':
        return 'Gagal';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return 'Status: $status';
    }
  }

  bool get isPending => status.toLowerCase() == 'pending';
}
