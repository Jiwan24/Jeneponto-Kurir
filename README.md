# Jeneponto Kurir 🛵📦

Aplikasi layanan kurir/wilayah **Kabupaten Jeneponto** — pelanggan mengirim paket,
kurir lokal menerima & mengantarkan, admin memantau seluruh transaksi.

**Arsitektur: Clean Architecture + Feature-First + Bloc/Cubit + Firebase**

---

## 1. Ringkasan Peran (Multi-Role)

| Peran    | Halaman utama                                  | Alur inti |
|----------|------------------------------------------------|-----------|
| Customer | Beranda, Pesanan Saya, Profil                  | Buat pesanan → bayar/tunggu kurir → lacak status |
| Kurir    | Dashboard (Order Tersedia, Tugas Saya), Profil | Terima order → ambil paket → antar → tandai terkirim |
| Admin    | Dashboard (ringkasan + semua pesanan), Profil  | Pantau statistik & transaksi |

Akun **Admin** tidak dibuat dari aplikasi — daftarkan manual di Firebase Console
(lihat bagian 6).

---

## 2. Arsitektur

Pola **Clean Architecture** diterapkan per fitur (*feature-first*), sehingga
setiap fitur berdiri sendiri dan mudah diuji/diganti.

```
┌─────────────────────────────────────────────────────────────┐
│  presentation/   UI (Page/Widget) + Bloc/Event/State        │
│      │  hanya bicara lewat repository (interface)           │
├─────────────────────────────────────────────────────────────┤
│  domain/         Entity + Repository (abstract)            │
│      │  aturan bisnis murni, TANPA dependensi Firebase      │
├─────────────────────────────────────────────────────────────┤
│  data/           Model + RemoteDataSource + RepositoryImpl  │
│      │  menerjemahkan exception → Failure (dartz Either)    │
└─────────────────────────────────────────────────────────────┘
                    │
              Firebase (Auth + Firestore)
```

**Prinsip aliran data (satu arah):**

```
Event → Bloc → Repository (interface) → RepositoryImpl → DataSource → Firestore
   ↑                                                           │
   └────────────── State ←─────────────────────────────────────┘
                          (stream realtime)
```

- **Domain** tidak tahu Flutter/Firebase → bisnis gampang diuji unit test.
- **Bloc** hanya menerima `Event` dan memancarkan `State`.
- **Failure** (`core/error/failures.dart`) dibungkus `Either<Failure, T>` dengan
  `dartz`, sehingga error teknis (Firebase) tidak pernah bocor ke UI.
- **Routing & guard** ditangani `GoRouter` yang mendengarkan stream `AuthBloc`
  (`core/router/app_router.dart`) — user belum login selalu dialihkan ke `/login`.
- **Dependency Injection** memakai `get_it` (`core/di/injector.dart`).
  `AuthBloc` = singleton (dipakai router), bloc halaman = factory (stream segar
  per halaman/user).

### Struktur folder

```
lib/
├── main.dart                      # inisialisasi Firebase + locale + DI
├── app.dart                       # MaterialApp.router + AuthBloc global
├── core/                          # lintasan lintas-fitur (tidak tahu fitur)
│   ├── config/firebase_options.dart
│   ├── constants/                 # app_constants, firestore_collections
│   ├── di/injector.dart           # get_it service locator
│   ├── error/                     # failures.dart, exceptions.dart
│   ├── router/                    # app_router.dart (guard auth)
│   ├── theme/                     # app_colors, app_theme (Material 3)
│   ├── utils/                     # formatters, validators, price_calculator
│   └── widgets/                   # app_button, app_text_field, empty_state
└── features/
    ├── auth/                      # login, register, session
    │   ├── domain/  (entities, repositories)
    │   ├── data/    (models, datasources, repositories)
    │   └── presentation/ (bloc, pages)
    ├── order/                      # pesanan: buat, list, batalkan
    │   └── ... + presentation/widgets (order_card, order_status_badge)
    ├── courier/                     # dashboard kurir + progres status
    ├── admin/                       # dashboard admin
    ├── home/                        # shell (bottom nav per peran) + beranda
    ├── profile/                     # profil & logout
    └── splash/                      # layar pembuka
test/
└── core/utils/                     # unit test kalkulator tarif & validator
firebase/
├── firestore.rules                 # keamanan data per peran
└── firestore.indexes.json          # composite index untuk query order
```

---

## 3. Model Data (Firestore)

### `users/{uid}`
```jsonc
{
  "uid": "abc123",
  "name": "Budi",
  "email": "budi@mail.com",
  "phone": "0812...",
  "role": "customer | courier | admin",
  "photoUrl": null,
  "createdAt": "<timestamp>"
}
```

### `orders/{id}`
```jsonc
{
  "customerId": "uid-pelanggan",
  "customerName": "Budi",
  "courierId": "uid-kurir | null",
  "courierName": "Andi | null",
  "pickupAddress": "Jl. ..., Jeneponto",
  "destinationAddress": "Pasar Binamu, Jeneponto",
  "note": "barang pecah belah",
  "distanceKm": 4.5,
  "price": 19500,                    // lihat PriceCalculator
  "status": "pending | accepted | pickedUp | inTransit | delivered | cancelled",
  "createdAt": "<timestamp>",
  "updatedAt": "<timestamp>"
}
```

**Mesin status (kurir):**
`pending → (terima) accepted → pickedUp → inTransit → delivered`
— pelanggan hanya boleh membatalkan saat masih `pending`.

**Tarif (MVP):** `Rp 8.000 + Rp 2.500/km` (min. 1 km), dibulatkan ke atas
per Rp 500 → `core/utils/price_calculator.dart`.

---

## 4. Tech Stack

| Kebutuhan | Pilihan | Alasan |
|---|---|---|
| State management | `flutter_bloc` | event-driven, mudah di-test (`bloc_test`) |
| Routing | `go_router` + guard auth | deklaratif, redirect berbasis stream |
| DI | `get_it` | ringan, tanpa codegen |
| Functional | `dartz` (`Either`) | error handling eksplisit |
| Backend | Firebase Auth, Firestore, Storage, FCM | cepat untuk MVP, realtime bawaan |
| UI | Material 3 | tema konsisten |

---

## 5. Menjalankan Proyek

Prasyarat: Flutter SDK terbaru, akun Firebase, Node.js (untuk CLI Firebase).

```sh
# 1. Buat platform folder (android/ios) — scaffold ini berisi kode Dart saja
flutter create . --org com.jeneponto --project-name jeneponto_kurir

# 2. Ambil dependensi
flutter pub get

# 3. Hubungkan Firebase (menimpa lib/core/config/firebase_options.dart)
dart pub global activate flutterfire_cli
flutterfire configure --project=jeneponto-kurir

# 4. Aktifkan "Email/Password" di Firebase Console → Authentication → Sign-in method
#    dan buat database Firestore (mode production lalu atur rules)

# 5. Deploy keamanan & index
firebase deploy --only firestore:rules,firestore:indexes

# 6. Jalankan
flutter run
```

> Bila konfigurasi Firebase belum diisi, aplikasi menampilkan layar panduan
> (`SetupRequiredApp`) alih-alih crash.

### Membuat akun Admin
1. Daftar dulu dari aplikasi sebagai **Customer** (atau buat user manual).
2. Di Firebase Console → Firestore → dokumen `users/{uid}`, ubah
   `"role": "admin"`.
3. Logout & login ulang → menu berubah menjadi dashboard admin.

### Menambah kurir
Daftar dari aplikasi memilih peran **Kurir** — langsung bisa melihat order
`pending`.

---

## 6. Pengujian

```sh
flutter test          # unit test tarif & validator
flutter analyze
```

Struktur test mengikuti pola `bloc_test` + `mocktail` (sudah ditambahkan ke
`dev_dependencies`) — contoh yang disarankan berikutnya:
`test/features/auth/presentation/auth_bloc_test.dart`.

---

## 7. Roadmap (fitur berikutnya)

1. **Peta & jarak otomatis** — `google_maps_flutter` + `geolocator`,
   ganti input jarak manual (komentar di `pubspec.yaml` sudah disiapkan).
2. **Notifikasi FCM** — notifikasi order baru ke kurir, status ke pelanggan.
3. **Lacak kurir realtime** — simpan posisi kurir, tampilkan di peta.
4. **Unggah bukti kirim** — `firebase_storage` + `image_picker`
   (dependensi sudah terpasang).
5. **Pembayaran** — QRIS/transfer manual + unggah bukti.
6. **Penilaian kurir** & riwayat laporan admin (export CSV).

---

## 8. Catatan Teknis Penting

- **Composite index**: query `orders` butuh index gabungan — sudah didefinisikan
  di `firebase/firestore.indexes.json` dan otomatis ter-deploy pada langkah 5.
  (Bila lupa, pesan error Firestore akan mencantumkan tautan pembuatannya.)
- **Keamanan**: `firebase/firestore.rules` membatasi akses per peran — pelanggan
  hanya membaca pesanannya, kurir hanya menerima/memajukan order miliknya,
  admin penuh. Ganti aturan bila model bisnis berubah.
- **Nama collection** (`users`, `orders`) dikunci di
  `core/constants/firestore_collections.dart`.
- Lokasi kode: seluruh rute di `core/router/app_router.dart` — tambahkan route
  baru di sini, bukan dengan `Navigator.push` manual.
