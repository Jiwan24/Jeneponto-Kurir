# Jeneponto Kurir — Person 2 (Customer & Financial)

Branch `person2-only` hanya berisi deliverable **Orang 2**: pemesanan customer,
pembayaran, dan dompet kurir. Kode Person 1 (fondasi/auth/profile/home) dan
Person 3 (courier/chat) sudah dihapus dari branch ini sesuai pembagian scope.

> **Penting:** branch ini bukan aplikasi utuh yang bisa langsung dijalankan.
> Modul Person 2 masih membutuhkan fondasi bersama dari Person 1 dan titik
> integrasi dari Person 3. Daftar dependensinya ada di bagian
> [Dependensi integrasi](#dependensi-integrasi).

## Scope yang disertakan

| Area | Lokasi |
|------|--------|
| Pemesanan customer, peta, tarif, riwayat, pelacakan | `lib/features/delivery/` |
| Pembayaran COD dan Midtrans Snap | `lib/features/payments/` |
| Dompet kurir dan riwayat transaksi | `lib/features/wallet/` |
| Backend pembayaran, COD settlement, wallet ledger | `functions/` |
| Firestore rules dan indexes | `firebase/` |
| Test tarif, validasi, checkout, pembayaran, wallet | `test/features/` |
| Setup Midtrans | `docs/PAYMENT_SETUP.md` |

## Alur yang diserahkan

- Cari kurir dan formulir pemesanan.
- Alamat pengambilan/tujuan dan pemilihan titik peta.
- Validasi area layanan Kabupaten Jeneponto.
- Perhitungan estimasi tarif dan rincian biaya.
- Status pencarian kurir, detail pesanan, dan riwayat pengiriman.
- Pembayaran COD dan Midtrans Snap melalui Cloud Functions.
- Dompet kurir server-authoritative: saldo, komisi, minimum payout, dan riwayat.
- Backend merekalkulasi tarif di server dan mencatat ledger wallet.

## Dependensi integrasi

Modul Person 2 memakai fondasi berikut yang **sengaja tidak disertakan** di
branch ini:

- `lib/core/constants/` — konstanta tarif dan nama koleksi.
- `lib/core/di/injector.dart` — registrasi dependency.
- `lib/core/error/` — `Failure` dan exception.
- `lib/core/router/app_paths.dart` — path navigasi.
- `lib/core/theme/`, `core/widgets/`, `core/utils/` — komponen dan util bersama.
- `lib/features/auth/domain/entities/user_entity.dart` — identitas pengguna.
- `lib/features/auth/presentation/bloc/auth_bloc.dart` — user aktif.
- `lib/features/order/domain/entities/order_entity.dart` — model order legacy.
- `lib/app.dart` dan `lib/main.dart` — bootstrap aplikasi.
- Person 3: penyelesaian pengantaran yang memicu pencatatan wallet.

Untuk menjalankan aplikasi lengkap, gunakan branch `Kaiser` atau `main`, lalu
gabungkan modul Person 2 ke fondasi tersebut. Branch ini dapat dipakai untuk
review kode dan pengujian terisolasi setelah dependensi di atas disediakan.

## Backend dan keamanan

- Functions: `functions/index.js` (Midtrans callable/webhook, COD settlement,
  wallet trigger, rekalkulasi tarif).
- Rules: `firebase/firestore.rules`.
- Indexes: `firebase/firestore.indexes.json`.
- Panduan deploy dan secret: `docs/PAYMENT_SETUP.md`.
- Jangan commit `functions/.env.local` atau server key Midtrans. File tersebut
  sudah di-ignore.

## Verifikasi

Pada branch lengkap (`Kaiser`/`main`):

```sh
flutter analyze
flutter test
```

Pada branch `person2-only`, perintah tersebut belum bisa dijalankan sampai
dependensi integrasi di atas dipulihkan.
