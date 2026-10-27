# Demo Lokal (Firebase Emulator)

Panduan menjalankan aplikasi tanpa project Firebase produksi. Semua data demo
berada di Firebase Emulator Suite dan aman untuk eksperimen.

## Prasyarat

- Flutter 3.47+ dan Dart 3.13+
- Firebase CLI 15+
- Node.js 20+
- JDK 21
- Untuk Android: Android SDK + emulator/device

Jalankan semua perintah dari root repository.

## 1. Jalankan Firebase Emulator

```sh
cd functions && npm install && cd ..
firebase emulators:start --only auth,firestore,functions --project demo-jeneponto
```

Port yang dipakai:

| Layanan | Port |
|---------|------|
| Emulator UI | 4000 |
| Auth | 9099 |
| Firestore | 8080 |
| Cloud Functions | 5001 |

## 2. Seed Data Demo

Di terminal lain:

```sh
node tool/seed_emulator.mjs
```

Akun demo:

| Peran | Email | Password |
|-------|-------|----------|
| Customer | `customer@demo.test` | `password123` |
| Kurir | `courier@demo.test` | `password123` |
| Admin | `admin@demo.test` | `password123` |

## 3. Jalankan Web

```sh
flutter run -d chrome -t lib/main_emulator.dart --web-port=5000
```

Atau build lalu serve statis:

```sh
flutter build web --release -t lib/main_emulator.dart
node tool/serve_web.mjs
```

Buka <http://127.0.0.1:5000>.

## 4. Jalankan Android

Pastikan emulator Android sudah menyala dan terdeteksi oleh `adb devices`.
Contoh membuat AVD (sekali saja):

```sh
avdmanager create avd -n Jeneponto_API35 \
  -k "system-images;android-35;google_apis;x86_64" -d medium_phone
emulator -avd Jeneponto_API35
```

Build dan jalankan aplikasi:

```sh
flutter build apk --debug -t lib/main_emulator.dart
adb install -r build/app/outputs/flutter-apk/app-debug.apk
adb shell am start -n com.jeneponto.jeneponto_kurir/.MainActivity
```

Emulator Android menjangkau host lewat `10.0.2.2`, sehingga Auth, Firestore, dan
Functions tetap memakai emulator di mesin yang sama. Manifest debug mengizinkan
HTTP lokal (`usesCleartextTraffic`) khusus untuk kebutuhan demo.

Di Windows, akselerasi emulator bisa memakai Android Emulator Hypervisor Driver.
Dari root Android SDK:

```sh
cmdline-tools\latest\bin\android.exe sdk install extras/google/Android_Emulator_Hypervisor_Driver
```

Lalu jalankan `silent_install.bat` dari folder package tersebut sebagai
Administrator, dan verifikasi dengan `emulator -accel-check`.

## Batasan Demo

- `lib/main_emulator.dart` memakai `FirebaseOptions` dummy dan hanya untuk
  emulator lokal.
- Pembayaran online (Midtrans) membutuhkan Cloud Functions yang sudah dideploy
  beserta secret Midtrans. Tanpa itu, halaman pembayaran online akan menampilkan
  kegagalan saat membuat transaksi.
- Pembayaran COD bisa diuji tanpa konfigurasi Midtrans.
- Data emulator hilang saat emulator dihentikan, kecuali memakai opsi export/
  import data Firebase Emulator.
