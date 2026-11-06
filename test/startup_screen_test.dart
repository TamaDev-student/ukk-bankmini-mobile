import 'package:customer_mobile/models/customer_account.dart';
import 'package:customer_mobile/models/customer_transaction.dart';
import 'package:customer_mobile/screens/auth/first_change_password_screen.dart';
import 'package:customer_mobile/screens/home/dashboard_screen.dart';
import 'package:customer_mobile/screens/auth/login_screen.dart';
import 'package:customer_mobile/screens/auth/startup_screen.dart';
import 'package:customer_mobile/services/auth_service.dart';
import 'package:customer_mobile/services/customer_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';

class _StubAuthService extends AuthService {
  _StubAuthService({this.token, this.mustChangePassword = false})
    : super(
        client: MockClient((_) async => throw StateError('Unexpected HTTP')),
      );

  final String? token;
  final bool mustChangePassword;
  var clearedSession = false;

  @override
  Future<String?> getToken() async => token;

  @override
  Future<bool> requiresInitialPasswordChange() async => mustChangePassword;

  @override
  Future<void> clearStoredSession() async {
    clearedSession = true;
  }
}

class _StubCustomerService extends CustomerService {
  _StubCustomerService({this.accountUnauthorized = true})
    : super(
        client: MockClient((_) async => throw StateError('Unexpected HTTP')),
      );

  final bool accountUnauthorized;
  var accountRequests = 0;

  @override
  Future<CustomerAccount> getAccount() async {
    accountRequests++;
    if (accountUnauthorized) {
      throw CustomerApiException(message: 'Sesi berakhir.', statusCode: 401);
    }
    return const CustomerAccount(
      accountNumber: '1234567890',
      studentNumber: '12345',
      studentName: 'Nasabah Uji',
      className: 'XII RPL',
      balance: 100000,
      status: 'active',
      hasPin: true,
    );
  }

  @override
  Future<List<CustomerTransaction>> getTransactions() async => [];

  @override
  Future<void> registerFcmToken(String token) async {}
}

Future<void> _pumpStartup(
  WidgetTester tester,
  _StubAuthService auth,
  _StubCustomerService customer,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: StartupScreen(authService: auth, customerService: customer),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('sesi tanpa token diarahkan ke login', (tester) async {
    final auth = _StubAuthService();
    final customer = _StubCustomerService();
    addTearDown(auth.dispose);
    addTearDown(customer.dispose);

    await _pumpStartup(tester, auth, customer);

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(customer.accountRequests, 0);
  });

  testWidgets('sesi yang valid diarahkan ke Dashboard', (tester) async {
    final auth = _StubAuthService(token: 'valid-session');
    final customer = _StubCustomerService(accountUnauthorized: false);
    addTearDown(auth.dispose);
    addTearDown(customer.dispose);

    await _pumpStartup(tester, auth, customer);

    expect(find.byType(DashboardScreen), findsOneWidget);
    expect(customer.accountRequests, 1);
    expect(auth.clearedSession, isFalse);
  });

  testWidgets('wajib ganti password diarahkan sebelum memeriksa rekening', (
    tester,
  ) async {
    final auth = _StubAuthService(token: 'session', mustChangePassword: true);
    final customer = _StubCustomerService();
    addTearDown(auth.dispose);
    addTearDown(customer.dispose);

    await _pumpStartup(tester, auth, customer);

    expect(find.byType(FirstChangePasswordScreen), findsOneWidget);
    expect(customer.accountRequests, 0);
  });

  testWidgets('sesi API tidak valid dibersihkan dan diarahkan ke login', (
    tester,
  ) async {
    final auth = _StubAuthService(token: 'expired-session');
    final customer = _StubCustomerService();
    addTearDown(auth.dispose);
    addTearDown(customer.dispose);

    await _pumpStartup(tester, auth, customer);

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(auth.clearedSession, isTrue);
    expect(customer.accountRequests, 1);
  });
}
