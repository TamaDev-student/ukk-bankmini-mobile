# 📱 Customer Mobile — E-Teller Bank Mini Sekolah

Aplikasi mobile berbasis Flutter yang dikembangkan untuk nasabah dalam sistem **E-Teller Bank Mini Sekolah**. Aplikasi ini memungkinkan nasabah mengakses informasi rekening, memantau saldo, melihat riwayat transaksi, serta melakukan konfirmasi transaksi melalui perangkat mobile.

Aplikasi terintegrasi dengan backend Laravel REST API untuk mengelola autentikasi, mengambil data rekening, dan memproses transaksi secara terpusat.

## ✨ Fitur Utama

- **Autentikasi Nasabah** — Login untuk mengakses akun nasabah.
- **Informasi Rekening** — Menampilkan informasi rekening dan saldo nasabah.
- **Riwayat Transaksi** — Melihat transaksi yang tercatat pada rekening.
- **Konfirmasi Transaksi** — Mendukung konfirmasi transaksi melalui aplikasi sesuai alur dan otorisasi backend.
- **Integrasi REST API** — Berkomunikasi dengan backend Laravel menggunakan API.
- **Keamanan Akses** — Menggunakan autentikasi berbasis token untuk mengakses endpoint yang memerlukan autentikasi.

## 🛠️ Teknologi

| Teknologi | Kegunaan |
|---|---|
| Flutter | Pengembangan aplikasi mobile |
| Dart | Bahasa pemrograman aplikasi |
| Laravel REST API | Backend dan pemrosesan bisnis |
| MySQL | Penyimpanan data terpusat |
| Bearer Token | Autentikasi permintaan API |

## 🏗️ Arsitektur Sistem

Aplikasi Customer Mobile merupakan bagian dari arsitektur client-server E-Teller Bank Mini Sekolah.

```text
┌──────────────────────────┐
│   Customer Mobile        │
│   Flutter + Dart         │
└────────────┬─────────────┘
             │
             │ HTTP / REST API
             │ Bearer Token
             ▼
┌──────────────────────────┐
│   Backend                │
│   Laravel REST API       │
└────────────┬─────────────┘
             │
             ▼
┌──────────────────────────┐
│   Database               │
│   MySQL                  │
└──────────────────────────┘
```

Aplikasi mobile tidak mengakses database secara langsung. Seluruh permintaan data dan pemrosesan transaksi dilakukan melalui backend Laravel agar validasi, otorisasi, dan aturan bisnis tetap terpusat.

## ⚙️ Persyaratan

Pastikan perangkat pengembangan telah memiliki:

- Flutter SDK
- Dart SDK yang kompatibel dengan versi Flutter
- Android Studio atau Visual Studio Code
- Android SDK untuk menjalankan aplikasi Android
- Backend Laravel REST API yang dapat diakses
- Git

## 🚀 Instalasi dan Menjalankan Aplikasi

### 1. Clone Repository

```bash
git clone <URL_REPOSITORY>
cd customer-mobile
```

Ganti `<URL_REPOSITORY>` dengan URL repository GitHub yang sebenarnya.

### 2. Instal Dependensi

```bash
flutter pub get
```

### 3. Konfigurasi Backend API

Sesuaikan konfigurasi base URL API pada aplikasi dengan alamat backend Laravel yang digunakan.

Contoh alamat untuk pengembangan lokal:

```text
http://10.0.2.2:8000/api
```

Alamat tersebut merupakan contoh untuk Android Emulator yang mengakses server pengembangan pada komputer host. Jika menggunakan perangkat fisik atau server production, gunakan alamat yang sesuai dengan lingkungan tersebut.

Jangan menyimpan token autentikasi, password, atau kredensial sensitif di dalam repository.

### 4. Periksa Koneksi Perangkat

```bash
flutter devices
```

Pastikan emulator atau perangkat Android terdeteksi.

### 5. Jalankan Aplikasi

```bash
flutter run
```

## 🧪 Pemeriksaan Kode

Untuk memeriksa masalah statis pada kode Flutter, jalankan:

```bash
flutter analyze
```

Untuk menjalankan pengujian yang tersedia:

```bash
flutter test
```

Hasil pengujian bergantung pada kondisi kode dan test yang terdapat dalam repository.

## 🔐 Keamanan

- Autentikasi dan otorisasi ditangani oleh backend.
- Token digunakan untuk mengakses endpoint yang memerlukan autentikasi.
- Validasi transaksi dilakukan oleh backend, bukan hanya oleh aplikasi mobile.
- PIN transaksi tidak boleh disimpan dalam bentuk plaintext atau ditampilkan dalam log.
- Informasi sensitif tidak boleh dimasukkan ke dalam repository publik.

## 🎯 Tujuan Proyek

E-Teller Bank Mini Sekolah dikembangkan sebagai proyek UKK kelas XII Rekayasa Perangkat Lunak (RPL) untuk menerapkan pengembangan aplikasi mobile, integrasi REST API, autentikasi, pengelolaan data, dan pemrosesan transaksi dalam arsitektur client-server.

## 📄 Lisensi

Lisensi proyek dapat ditentukan sesuai kebutuhan pengembang atau ketentuan proyek sekolah.****
