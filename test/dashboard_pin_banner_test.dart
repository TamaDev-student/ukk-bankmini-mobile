import 'package:customer_mobile/models/customer_account.dart';
import 'package:customer_mobile/models/customer_transaction.dart';
import 'package:customer_mobile/screens/home/dashboard_screen.dart';
import 'package:customer_mobile/services/customer_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _StubCustomerService extends CustomerService {
  _StubCustomerService(this.account, {this.transactions = const []})
    : super(client: MockClient((_) async => http.Response('{}', 200)));

  final CustomerAccount account;
  final List<CustomerTransaction> transactions;

  @override
  Future<CustomerAccount> getAccount() async => account;

  @override
  Future<List<CustomerTransaction>> getTransactions() async => transactions;
}

CustomerAccount _account({
  bool hasPin = false,
  bool pinLocked = false,
  bool pinRecoveryInProgress = false,
  bool hasPendingPinReset = false,
}) {
  return CustomerAccount(
    accountNumber: 'RPL001',
    studentNumber: '001234',
    studentName: 'Siswa Uji',
    className: 'X RPL 1',
    balance: 10000,
    status: 'active',
    hasPin: hasPin,
    pinLocked: pinLocked,
    pinRecoveryInProgress: pinRecoveryInProgress,
    hasPendingPinReset: hasPendingPinReset,
  );
}

Future<void> _showDashboard(
  WidgetTester tester,
  CustomerAccount account, {
  List<CustomerTransaction> transactions = const [],
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: DashboardScreen(
        customerService: _StubCustomerService(
          account,
          transactions: transactions,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('nasabah tanpa PIN mendapat banner dan dapat membuka setup', (
    tester,
  ) async {
    await _showDashboard(tester, _account());

    expect(find.text('PIN Transaksi Belum Dibuat'), findsOneWidget);
    expect(find.text('Buat PIN Sekarang'), findsOneWidget);
    expect(
      find.text(
        'Kamu sudah memiliki rekening. Buat PIN transaksi 6 digit terlebih dahulu agar dapat melakukan penarikan tunai.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Buat PIN Sekarang'));
    await tester.pumpAndSettle();

    expect(find.text('PIN Baru'), findsOneWidget);
  });

  testWidgets('nasabah dengan PIN aktif tidak mendapat banner pembuatan PIN', (
    tester,
  ) async {
    await _showDashboard(tester, _account(hasPin: true));

    expect(find.text('PIN Transaksi Belum Dibuat'), findsNothing);
    expect(find.text('Buat PIN Sekarang'), findsNothing);
  });

  testWidgets('PIN terkunci dan pemulihan diproses tidak diarahkan ke setup', (
    tester,
  ) async {
    await _showDashboard(tester, _account(hasPin: true, pinLocked: true));

    expect(find.text('PIN Transaksi Terkunci'), findsOneWidget);
    expect(find.text('Buat PIN Sekarang'), findsNothing);
    expect(find.text('Kelola PIN'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await _showDashboard(
      tester,
      _account(hasPin: true, hasPendingPinReset: true),
    );

    expect(find.text('Pemulihan PIN Sedang Diproses'), findsOneWidget);
    expect(find.text('Buat PIN Sekarang'), findsNothing);
  });

  testWidgets('transaksi dibatalkan memakai ikon dan nominal khusus merah', (
    tester,
  ) async {
    final transaction = CustomerTransaction(
      id: 21,
      transactionDate: DateTime(2026, 11, 6),
      transactionType: 'deposit',
      amount: 25000,
      status: 'cancelled',
    );
    await _showDashboard(
      tester,
      _account(hasPin: true),
      transactions: [transaction],
    );

    final cancelledAmount = find.text('Dibatalkan\nRp 25.000');
    await tester.scrollUntilVisible(
      cancelledAmount,
      300,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.byIcon(Icons.cancel_outlined), findsOneWidget);
    expect(cancelledAmount, findsOneWidget);
    expect(
      tester.widget<Text>(cancelledAmount).style?.color,
      const Color(0xFFDC2626),
    );
    expect(find.text('Dibatalkan'), findsOneWidget);
  });
}
