import 'package:customer_mobile/screens/auth/first_change_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('password awal memvalidasi kekuatan dan konfirmasi', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: FirstChangePasswordScreen()),
    );

    final passwordField = find.byType(TextFormField).at(0);
    final confirmationField = find.byType(TextFormField).at(1);

    await tester.enterText(passwordField, 'weakpass1');
    await tester.enterText(confirmationField, 'weakpass1');
    await tester.tap(find.text('Simpan Password'));
    await tester.pumpAndSettle();

    expect(find.text('Gunakan minimal 10 karakter.'), findsOneWidget);

    await tester.enterText(passwordField, 'PermanentPass123');
    await tester.enterText(confirmationField, 'DifferentPass123');
    await tester.tap(find.text('Simpan Password'));
    await tester.pumpAndSettle();

    expect(find.text('Konfirmasi password tidak cocok.'), findsOneWidget);
  });
}
