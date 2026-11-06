import 'package:customer_mobile/screens/help/help_center_screen.dart';
import 'package:customer_mobile/screens/profile/profile_screen.dart';
import 'package:customer_mobile/models/customer_account.dart';
import 'package:customer_mobile/services/customer_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _StubCustomerService extends CustomerService {
  _StubCustomerService()
    : super(client: MockClient((_) async => http.Response('{}', 200)));

  @override
  Future<CustomerAccount> getAccount() async {
    return const CustomerAccount(
      accountNumber: 'RPL001',
      studentNumber: '001234',
      studentName: 'Siswa Uji',
      className: 'X RPL 1',
      balance: 10000,
      status: 'active',
      hasPin: true,
      recoveryEmailVerified: true,
    );
  }
}

Future<void> _pumpHelpCenter(
  WidgetTester tester, {
  Size size = const Size(400, 800),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(const MaterialApp(home: HelpCenterScreen()));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('panduan dapat dibuka dan kembali ke pusat bantuan', (
    tester,
  ) async {
    await _pumpHelpCenter(tester);

    expect(find.text('Pusat Bantuan'), findsOneWidget);
    expect(find.text('Panduan Penggunaan'), findsOneWidget);
    expect(find.text('Melihat informasi rekening dan saldo'), findsOneWidget);

    await tester.tap(find.text('Melihat informasi rekening dan saldo'));
    await tester.pumpAndSettle();

    expect(find.text('Langkah-langkah'), findsOneWidget);
    expect(
      find.text('Masuk ke aplikasi dan buka halaman Beranda.'),
      findsOneWidget,
    );

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('Pusat Bantuan'), findsOneWidget);
  });

  testWidgets('pusat bantuan dapat dibuka dari halaman Profil', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: ProfileScreen(customerService: _StubCustomerService())),
    );
    await tester.pumpAndSettle();

    final helpEntry = find.text('Pusat Bantuan');
    await tester.scrollUntilVisible(
      helpEntry,
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(helpEntry);
    await tester.pumpAndSettle();

    expect(find.text('Panduan Penggunaan'), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
  });

  testWidgets('navigasi Profil menampilkan empat menu dan kembali ke Beranda', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => ProfileScreen(
                        customerService: _StubCustomerService(),
                      ),
                    ),
                  );
                },
                child: const Text('Buka Profil'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Buka Profil'));
    await tester.pumpAndSettle();

    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('Mutasi'), findsOneWidget);
    expect(find.text('Persetujuan'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);

    await tester.tap(find.text('Beranda'));
    await tester.pumpAndSettle();

    expect(find.text('Buka Profil'), findsOneWidget);
  });

  testWidgets('pencarian menemukan konten panduan dan FAQ', (tester) async {
    await _pumpHelpCenter(tester);

    await tester.enterText(find.byType(TextField), 'OTP');
    await tester.pumpAndSettle();

    expect(find.text('Masuk dan memulihkan kata sandi'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Apa yang harus dilakukan jika lupa kata sandi?'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.text('Apa yang harus dilakukan jika lupa kata sandi?'),
      findsOneWidget,
    );
  });

  testWidgets('FAQ dapat dibuka dan ditutup', (tester) async {
    await _pumpHelpCenter(tester);

    final question = find.text('Apa arti status Menunggu Konfirmasi?');
    await tester.scrollUntilVisible(
      question,
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(question);
    await tester.pumpAndSettle();

    const answer =
        'Transaksi masih berstatus pending dan menunggu proses atau konfirmasi yang diperlukan. Periksa kembali status terbaru di Mutasi. Transaksi pending dapat dibatalkan dari detail transaksi.';
    expect(find.text(answer), findsOneWidget);

    await tester.tap(question);
    await tester.pumpAndSettle();
    expect(find.text(answer), findsNothing);
  });

  testWidgets('hasil kosong informatif dan pencarian dapat dihapus', (
    tester,
  ) async {
    await _pumpHelpCenter(tester);

    await tester.enterText(find.byType(TextField), 'kata yang tidak ada');
    await tester.pumpAndSettle();

    expect(find.text('Panduan tidak ditemukan'), findsOneWidget);
    expect(
      find.text('Coba kata kunci lain atau tampilkan semua kategori.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Hapus pencarian'));
    await tester.pumpAndSettle();

    expect(find.text('Panduan tidak ditemukan'), findsNothing);
    expect(find.text('Panduan Penggunaan'), findsOneWidget);
  });

  testWidgets('layout dapat dibaca pada layar kecil tanpa overflow', (
    tester,
  ) async {
    await _pumpHelpCenter(tester, size: const Size(320, 640));

    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.text('Apa arti status Menunggu Konfirmasi?'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
