import 'package:customer_mobile/screens/profile/pin_setup_screen.dart';
import 'package:customer_mobile/services/customer_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';

void main() {
  testWidgets('pembuatan PIN memvalidasi enam digit dan konfirmasi', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PinSetupScreen(
          customerService: CustomerService(
            client: MockClient(
              (_) async => throw StateError('Unexpected request'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Buat PIN Transaksi'), findsNWidgets(2));
    expect(
      find.text(
        'Buat PIN 6 digit yang akan digunakan untuk mengonfirmasi transaksi penarikan.',
      ),
      findsOneWidget,
    );

    final pinField = find.byType(TextFormField).at(0);
    final confirmationField = find.byType(TextFormField).at(1);
    final submitButton = find.text('Simpan PIN');

    await tester.enterText(pinField, '12345');
    await tester.enterText(confirmationField, '12345');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();
    expect(
      find.text('PIN harus terdiri dari 6 digit angka.'),
      findsNWidgets(2),
    );

    await tester.enterText(pinField, '123456');
    await tester.enterText(confirmationField, '654321');
    await tester.tap(submitButton);
    await tester.pumpAndSettle();
    expect(find.text('Konfirmasi PIN tidak cocok.'), findsOneWidget);
  });
}
