# Jeneponto Kurir — Person 2 (Customer & Financial)

Branch `person2-only` hanya berisi deliverable **Orang 2**: pemesanan customer,
pembayaran, dan dompet kurir. Tidak ada kode login/auth, profil, beranda,
maupun fitur kurir/chat dari Person 1 atau Person 3.

> Branch ini adalah **modul fitur**, bukan aplikasi utuh. Tidak ada `main.dart`
> atau shell aplikasi. Host aplikasi cukup memanggil registrasi dependency dan
> mengirim ID pengguna ke halaman Person 2.

## Scope yang disertakan

| Area | Lokasi |
|------|--------|
| Pemesanan customer, peta, tarif, riwayat, pelacakan | `lib/features/delivery/` |
| Pembayaran COD dan Midtrans Snap | `lib/features/payments/` |
| Dompet kurir dan riwayat transaksi | `lib/features/wallet/` |
| Komponen/utility internal Person 2 | `lib/features/common/` |
| Backend pembayaran, COD settlement, wallet ledger | `functions/` |
| Firestore rules dan indexes | `firebase/` |
| Test tarif, validasi, checkout, pembayaran, wallet | `test/features/` |
| Setup Midtrans | `docs/PAYMENT_SETUP.md` |

## Prinsip integrasi

Person 2 **tidak menangani autentikasi**. Halaman menerima identitas dari host:

- `SearchCourierPage(customerId:, customerName:, customerPhone:)`
- `DeliveryHistoryPage(customerId:)`
- `WalletPage(courierId:)`

Host aplikasi bertanggung jawab untuk login, role, navigasi, dan tema global.
Registrasi dependency dilakukan sekali setelah `Firebase.initializeApp`:

```dart
import 'package:jeneponto_kurir/features/common/di/person2_locator.dart';

await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
await initPerson2Dependencies();
```

Path route tersedia di `lib/features/common/router/app_paths.dart`.

## Yang sengaja tidak ada

- Login, registrasi, `AuthBloc`, `UserEntity`, dan role check.
- `OrderEntity` / fitur order lama. Status pesanan Person 2 memakai
  `OrderStatus` lokal di `delivery/domain/entities/order_status.dart`.
- Fitur kurir, chat, notifikasi, unggah bukti, dan profil.
- Shell aplikasi, beranda, dan router global.

## Backend dan keamanan

- Functions: `functions/index.js` (Midtrans callable/webhook, COD settlement,
  wallet trigger, rekalkulasi tarif).
- Rules: `firebase/firestore.rules`.
- Indexes: `firebase/firestore.indexes.json`.
- Panduan deploy dan secret: `docs/PAYMENT_SETUP.md`.
- Jangan commit `functions/.env.local` atau server key Midtrans. File tersebut
  sudah di-ignore.

## Verifikasi

```sh
flutter pub get
flutter analyze
flutter test
```

Semua test Person 2 berjalan tanpa Firebase dan tanpa kode Person 1/3.
