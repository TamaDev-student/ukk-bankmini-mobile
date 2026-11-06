import 'package:customer_mobile/models/customer_account.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const baseAccount = {
    'account_number': 'RPL001',
    'student_number': '001234',
    'student_name': 'Siswa Uji',
    'class_name': 'X RPL 1',
    'balance': 50000,
    'status': 'active',
  };

  test('PIN kosong dikenali dari status backend', () {
    final account = CustomerAccount.fromJson({
      ...baseAccount,
      'has_pin': false,
      'pin_locked': false,
      'pin_recovery_in_progress': false,
    });

    expect(account.hasPin, isFalse);
    expect(account.pinLocked, isFalse);
    expect(account.pinRecoveryInProgress, isFalse);
  });

  test('PIN terkunci dan pemulihan aktif dibedakan dari PIN belum dibuat', () {
    final account = CustomerAccount.fromJson({
      ...baseAccount,
      'has_pin': true,
      'pin_locked': true,
      'pin_recovery_in_progress': true,
    });

    expect(account.hasPin, isTrue);
    expect(account.pinLocked, isTrue);
    expect(account.pinRecoveryInProgress, isTrue);
  });
}
