class CustomerAccount {
  const CustomerAccount({
    required this.accountNumber,
    required this.studentNumber,
    required this.studentName,
    required this.className,
    required this.balance,
    required this.status,
    required this.hasPin,
    this.pinLocked = false,
    this.pinRecoveryInProgress = false,
    this.mustChangePin = false,
    this.hasPendingPinReset = false,
    this.latestPinResetStatus,
    this.recoveryEmail,
    this.recoveryEmailVerified = false,
  });

  final String accountNumber;
  final String studentNumber;
  final String studentName;
  final String className;
  final int balance;
  final String status;
  final bool hasPin;
  final bool pinLocked;
  final bool pinRecoveryInProgress;
  final bool mustChangePin;
  final bool hasPendingPinReset;
  final String? latestPinResetStatus;

  // Email pemulihan akun.
  final String? recoveryEmail;

  // Status verifikasi kepemilikan email.
  final bool recoveryEmailVerified;

  factory CustomerAccount.fromJson(Map<String, dynamic> json) {
    return CustomerAccount(
      accountNumber: json['account_number']?.toString() ?? '',
      studentNumber: json['student_number']?.toString() ?? '',
      studentName: json['student_name']?.toString() ?? '',
      className: json['class_name']?.toString() ?? '-',
      balance: _parseBalance(json['balance']),
      status: json['status']?.toString() ?? '',
      hasPin: json['has_pin'] == true,
      pinLocked: json['pin_locked'] == true,
      pinRecoveryInProgress: json['pin_recovery_in_progress'] == true,
      mustChangePin: json['must_change_pin'] == true,
      hasPendingPinReset: json['has_pending_pin_reset'] == true,
      latestPinResetStatus: json['latest_pin_reset_status']?.toString(),

      recoveryEmail: _parseNullableString(json['recovery_email']),

      recoveryEmailVerified: json['recovery_email_verified'] == true,
    );
  }

  static String? _parseNullableString(dynamic value) {
    if (value == null) return null;

    final result = value.toString().trim();

    return result.isEmpty ? null : result;
  }

  static int _parseBalance(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();

    if (value is String) {
      final parsed = int.tryParse(value);

      if (parsed != null) {
        return parsed;
      }
    }

    throw const FormatException('Format saldo dari server tidak valid.');
  }
}
