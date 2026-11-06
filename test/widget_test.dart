// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:customer_mobile/widgets/splash_screen.dart';

void main() {
  testWidgets('Splash menampilkan identitas aplikasi dan indikator loading', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));
    await tester.pump(const Duration(milliseconds: 450));

    expect(find.bySemanticsLabel('Logo Bank Mini Sekolah'), findsOneWidget);
    expect(find.text('E-Teller Bank Mini'), findsOneWidget);
    expect(find.text('Sistem Informasi Bank Mini Sekolah'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final splash = find.byType(SplashScreen);
    expect(
      find.descendant(of: splash, matching: find.byType(FadeTransition)),
      findsNWidgets(2),
    );
    expect(
      find.descendant(of: splash, matching: find.byType(ScaleTransition)),
      findsWidgets,
    );
    expect(
      find.descendant(of: splash, matching: find.byType(SlideTransition)),
      findsWidgets,
    );
  });

  for (final size in [
    const Size(320, 568),
    const Size(360, 800),
    const Size(390, 844),
    const Size(440, 956),
  ]) {
    testWidgets(
      'Splash tidak overflow pada layar ${size.width}x${size.height}',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(const MaterialApp(home: SplashScreen()));
        await tester.pump(const Duration(milliseconds: 450));

        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Reduce Motion menampilkan Splash tanpa animasi loading', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: const SplashScreen(),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Logo Bank Mini Sekolah'), findsOneWidget);
    expect(find.text('E-Teller Bank Mini'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
