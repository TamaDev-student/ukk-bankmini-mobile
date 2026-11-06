class HelpGuide {
  const HelpGuide({
    required this.category,
    required this.title,
    required this.description,
    required this.steps,
    this.note,
  });

  final String category;
  final String title;
  final String description;
  final List<String> steps;
  final String? note;

  String get searchableText =>
      [category, title, description, ...steps, ?note].join(' ');
}

class HelpFaq {
  const HelpFaq({
    required this.category,
    required this.question,
    required this.answer,
  });

  final String category;
  final String question;
  final String answer;

  String get searchableText => '$category $question $answer';
}

const helpCategories = [
  'Semua',
  'Akun & Login',
  'PIN & Keamanan',
  'Saldo & Rekening',
  'Transaksi & Mutasi',
  'Kendala Aplikasi',
];

const helpGuides = [
  HelpGuide(
    category: 'Akun & Login',
    title: 'Masuk dan memulihkan kata sandi',
    description:
        'Gunakan NIS untuk masuk. Jika lupa kata sandi, ikuti pemulihan dengan OTP.',
    steps: [
      'Buka aplikasi E-Teller Bank Mini Sekolah.',
      'Masukkan NIS dan kata sandi akun, lalu pilih tombol masuk.',
      'Jika lupa kata sandi, pilih “Lupa Password?” pada halaman login.',
      'Masukkan NIS dan ikuti langkah verifikasi OTP yang dikirim ke email pemulihan.',
      'Setelah OTP terverifikasi, buat kata sandi baru dan masuk kembali.',
    ],
    note:
        'Jangan membagikan kata sandi atau kode OTP kepada siapa pun. Jika email pemulihan tidak dapat digunakan, minta bantuan petugas sekolah.',
  ),
  HelpGuide(
    category: 'Saldo & Rekening',
    title: 'Melihat informasi rekening dan saldo',
    description:
        'Saldo dan informasi rekening tersedia pada Beranda dan Profil Saya.',
    steps: [
      'Masuk ke aplikasi dan buka halaman Beranda.',
      'Lihat saldo pada kartu rekening. Gunakan tombol tampil/sembunyikan saldo sesuai kebutuhan.',
      'Tarik halaman ke bawah untuk memuat ulang informasi rekening dan transaksi.',
      'Untuk melihat nomor rekening dan informasi pemilik, buka Profil.',
    ],
  ),
  HelpGuide(
    category: 'Transaksi & Mutasi',
    title: 'Melihat mutasi dan detail transaksi',
    description:
        'Halaman Mutasi Rekening menampilkan riwayat, status, dan detail transaksi.',
    steps: [
      'Pilih menu Mutasi pada navigasi aplikasi.',
      'Temukan transaksi yang ingin diperiksa. Gunakan pencarian atau filter yang tersedia bila diperlukan.',
      'Pilih transaksi untuk membuka detailnya.',
      'Periksa jenis, nominal, tanggal, status, dan alasan penolakan jika informasi tersebut tersedia.',
      'Tarik daftar ke bawah untuk memuat ulang data terbaru.',
    ],
    note:
        'Pastikan status transaksi terbaru sebelum mengulangi tindakan yang sama.',
  ),
  HelpGuide(
    category: 'Transaksi & Mutasi',
    title: 'Membatalkan transaksi yang masih menunggu',
    description:
        'Transaksi hanya dapat dibatalkan dari detail ketika statusnya masih menunggu konfirmasi.',
    steps: [
      'Buka menu Mutasi dan pilih transaksi berstatus “Menunggu Konfirmasi”.',
      'Pada detail transaksi, pilih “Batalkan Transaksi”.',
      'Periksa pesan konfirmasi, lalu pilih “Ya, Batalkan” untuk melanjutkan atau “Tidak” untuk kembali.',
      'Setelah berhasil, periksa kembali detail dan riwayat. Status transaksi akan menjadi “Dibatalkan”.',
    ],
    note:
        'Transaksi yang telah dibatalkan tidak dapat diproses kembali. Transaksi yang sudah berstatus final tidak dapat dibatalkan.',
  ),
  HelpGuide(
    category: 'PIN & Keamanan',
    title: 'Membuat atau memulihkan PIN transaksi',
    description:
        'PIN transaksi 6 digit digunakan untuk konfirmasi penarikan dan dikelola dari Profil.',
    steps: [
      'Buka Profil Saya.',
      'Jika belum memiliki PIN, pilih “Buat PIN” dan ikuti petunjuk untuk membuat PIN 6 digit.',
      'Jika lupa atau PIN terkunci, pilih “Pulihkan PIN”.',
      'Minta OTP ke email pemulihan yang terdaftar, verifikasi kode, lalu buat dan konfirmasikan PIN baru.',
    ],
    note:
        'Pemulihan PIN memerlukan email pemulihan terverifikasi. Jangan membagikan PIN maupun OTP kepada siapa pun.',
  ),
  HelpGuide(
    category: 'Kendala Aplikasi',
    title: 'Mengatasi data yang belum diperbarui',
    description:
        'Muat ulang data dan periksa status transaksi sebelum mencoba kembali.',
    steps: [
      'Pastikan perangkat terhubung ke internet.',
      'Tarik halaman Beranda atau Mutasi ke bawah untuk memuat ulang data.',
      'Buka detail transaksi dan periksa status terakhir yang ditampilkan.',
      'Jika kendala tetap terjadi, catat pesan yang muncul dan sampaikan kepada petugas Bank Mini sekolah.',
    ],
    note:
        'Jangan mengulangi transaksi sebelum memastikan hasil transaksi sebelumnya.',
  ),
];

const helpFaqs = [
  HelpFaq(
    category: 'Akun & Login',
    question: 'Bagaimana cara login ke aplikasi?',
    answer:
        'Masukkan NIS dan kata sandi pada halaman login. Jika lupa kata sandi, gunakan pilihan “Lupa Password?” untuk mengikuti pemulihan melalui OTP.',
  ),
  HelpFaq(
    category: 'Akun & Login',
    question: 'Apa yang harus dilakukan jika lupa kata sandi?',
    answer:
        'Pada halaman login, pilih “Lupa Password?”, masukkan NIS, lalu ikuti verifikasi OTP melalui email pemulihan. Jika email tersebut tidak dapat diakses, hubungi petugas sekolah sesuai prosedur yang berlaku.',
  ),
  HelpFaq(
    category: 'PIN & Keamanan',
    question: 'Untuk apa PIN transaksi digunakan?',
    answer:
        'PIN transaksi digunakan untuk mengonfirmasi penarikan yang menunggu persetujuan di aplikasi. PIN baru terdiri dari 6 digit.',
  ),
  HelpFaq(
    category: 'PIN & Keamanan',
    question: 'Apa yang harus dilakukan jika lupa atau PIN terkunci?',
    answer:
        'Buka Profil Saya, pilih pemulihan PIN, lalu verifikasi OTP yang dikirim ke email pemulihan terverifikasi dan buat PIN baru. Jangan membagikan PIN atau OTP kepada siapa pun.',
  ),
  HelpFaq(
    category: 'Saldo & Rekening',
    question: 'Bagaimana cara melihat saldo rekening?',
    answer:
        'Saldo ditampilkan pada kartu rekening di Beranda dan pada bagian informasi rekening di Profil Saya. Tarik halaman ke bawah untuk meminta data terbaru.',
  ),
  HelpFaq(
    category: 'Saldo & Rekening',
    question: 'Mengapa saldo belum berubah setelah transaksi?',
    answer:
        'Periksa status transaksi terlebih dahulu, lalu muat ulang Beranda atau Mutasi. Jangan mengulangi transaksi sebelum memastikan status transaksi sebelumnya.',
  ),
  HelpFaq(
    category: 'Transaksi & Mutasi',
    question: 'Apa arti status Menunggu Konfirmasi?',
    answer:
        'Transaksi masih berstatus pending dan menunggu proses atau konfirmasi yang diperlukan. Periksa kembali status terbaru di Mutasi. Transaksi pending dapat dibatalkan dari detail transaksi.',
  ),
  HelpFaq(
    category: 'Transaksi & Mutasi',
    question: 'Apa arti status Berhasil?',
    answer:
        'Status Berhasil menunjukkan transaksi telah disetujui. Periksa detail transaksi dan saldo terbaru untuk memastikan informasi yang tercatat.',
  ),
  HelpFaq(
    category: 'Transaksi & Mutasi',
    question: 'Apa arti status Ditolak atau Gagal?',
    answer:
        'Status Ditolak atau Gagal berarti transaksi tidak selesai sebagai transaksi berhasil. Buka detail untuk melihat alasan penolakan jika tersedia. Jika belum jelas, sampaikan detail transaksi kepada petugas.',
  ),
  HelpFaq(
    category: 'Transaksi & Mutasi',
    question: 'Apa arti status Dibatalkan?',
    answer:
        'Transaksi berstatus Dibatalkan telah dibatalkan saat masih menunggu konfirmasi dan tidak dapat diproses kembali.',
  ),
  HelpFaq(
    category: 'Transaksi & Mutasi',
    question: 'Bagaimana cara melihat riwayat dan detail transaksi?',
    answer:
        'Buka menu Mutasi, pilih transaksi, lalu periksa jenis, nominal, tanggal, status, dan alasan penolakan jika tersedia. Tarik daftar ke bawah untuk memuat ulang.',
  ),
  HelpFaq(
    category: 'Kendala Aplikasi',
    question: 'Apa yang harus dilakukan jika riwayat tidak muncul?',
    answer:
        'Periksa koneksi internet, tarik halaman Mutasi ke bawah untuk memuat ulang, dan coba kembali. Jika tetap bermasalah, sampaikan pesan kendala kepada petugas Bank Mini sekolah.',
  ),
];
