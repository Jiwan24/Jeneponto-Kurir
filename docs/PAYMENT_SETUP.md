# Pembayaran & Dompet Kurir — Setup

Dokumen ini menjelaskan cara mengaktifkan pembayaran online (Midtrans Snap)
dan dompet kurir. Aplikasi tetap bisa dipakai dengan **COD** tanpa konfigurasi
tambahan.

## Arsitektur singkat

| Bagian | Lokasi | Penulis |
| --- | --- | --- |
| Pesanan | `orders/{orderId}` | Client (create/cancel), kurir (status), Cloud Function (pembayaran) |
| Pembayaran | `payments/{orderId}` | Cloud Function saja |
| Dompet | `wallets/{courierUid}` | Cloud Function saja |
| Mutasi dompet | `wallet_transactions/{id}` | Cloud Function saja |

Alur pembayaran online:

1. Pelanggan memilih **Bayar Online** di halaman Cari Kurir.
2. Pesanan dibuat dengan status `awaitingPayment` (tidak muncul di job board
   kurir).
3. Aplikasi memanggil callable `createMidtransPayment`.
4. Function membuat transaksi Snap, menyimpan `payments/{orderId}`, dan
   mengembalikan `token` + `redirectUrl`.
5. Pelanggan menyelesaikan pembayaran di browser.
6. Webhook `midtransWebhook` memverifikasi signature, mengubah status
   pembayaran menjadi `paid`, lalu memindahkan pesanan ke `pending` agar
   terlihat oleh kurir.
7. Saat kurir menandai `delivered`, trigger `onOrderDelivered` mencatat
   pembayaran COD (bila ada) dan mengkredit dompet kurir sebesar 90% dari
   tarif (komisi default 10%).

## 1. Prasyarat

- Project Firebase dengan Firestore (region Asia-Southeast2 disarankan).
- Blaze plan (Cloud Functions memerlukan billing).
- Akun Midtrans. Untuk pengembangan gunakan **Sandbox**.
- Firebase CLI: `npm install -g firebase-tools`.

## 2. Konfigurasi Midtrans

1. Masuk ke dashboard Midtrans Sandbox dan salin **Server Key**
   (`SB-Mid-server-...`).
2. Simpan sebagai secret Firebase:

   ```bash
   firebase functions:secrets:set MIDTRANS_SERVER_KEY
   ```

3. Buat `functions/.env.<projectId>` (jangan commit) berisi:

   ```dotenv
   MIDTRANS_IS_PRODUCTION=false
   PAYMENT_FINISH_URL=https://jeneponto-kurir.web.app/payment/finish
   ```

   Untuk produksi, ganti `MIDTRANS_IS_PRODUCTION=true` dan gunakan server
   key produksi. `PAYMENT_FINISH_URL` hanya halaman tujuan browser setelah
   pembayaran; aplikasi tetap memantau status lewat Firestore.

4. Deploy:

   ```bash
   firebase deploy --only functions,firestore:rules,firestore:indexes
   ```

5. Salin URL `midtransWebhook` dari output deploy (Cloud Functions v2
   memakai URL Cloud Run, bukan selalu `cloudfunctions.net`).

6. Di dashboard Midtrans, buka **Settings → Payment Notification URL** dan
   isi URL webhook tersebut. Aktifkan notifikasi untuk transaksi
   `capture`, `settlement`, `pending`, `deny`, `expire`, dan `cancel`.

## 3. Konfigurasi komisi & penarikan

- Komisi default 10% diambil dari `config/finance`:

  ```json
  {
    "commissionPct": 10
  }
  ```

  Jika dokumen tidak ada, function memakai 10%.

- Minimal penarikan ditampilkan dari konstanta aplikasi
  `AppConstants.minimumPayout` (Rp50.000). Penarikan saat ini diproses admin;
  client hanya menampilkan saldo dan riwayat.

## 4. Firestore rules

Rules baru:

- Pelanggan hanya bisa membuat pesanan dengan status `pending` (COD) atau
  `awaitingPayment` (gateway), dengan `paymentStatus` awal `unpaid`.
- Pelanggan hanya bisa membatalkan pesanan miliknya yang belum diambil kurir
  dan belum lunas.
- Kurir hanya bisa menerima order `pending` dan memajukan status satu langkah
  (`accepted` → `pickedUp` → `inTransit` → `delivered`). Harga, alamat, dan
  data pelanggan tidak bisa diubah kurir.
- Job board `pending` hanya terbaca oleh kurir (dan admin), bukan semua
  pengguna login.
- `payments`, `wallets`, dan `wallet_transactions` hanya bisa dibaca pemilik
  (atau admin); penulisan hanya lewat Admin SDK/Cloud Function.

Terapkan dengan:

```bash
firebase deploy --only firestore:rules,firestore:indexes
```

## 5. Pengujian sandbox

1. Login sebagai pelanggan, buat pesanan dengan **Bayar Online**.
2. Di halaman pembayaran, tekan **Bayar Sekarang**.
3. Browser terbuka ke halaman Snap. Gunakan kartu uji Midtrans, mis.
   `4811 1111 1111 1114`, masa berlaku bebas, CVV `123`, OTP `112233`.
4. Setelah selesai, kembali ke aplikasi dan tekan **Saya Sudah Bayar** bila
   status belum berubah otomatis.
5. Pesanan harus berpindah ke tab order kurir.
6. Login sebagai kurir, terima order, majukan status sampai **Terkirim**.
7. Buka **Profil → Dompet Kurir**: saldo dan riwayat pendapatan harus muncul.

Untuk COD, langkah 2–4 dilewati; pembayaran tercatat saat pengiriman selesai.

## 6. Troubleshooting

| Gejala | Penyebab umum |
| --- | --- |
| `failed-precondition` saat bayar | `MIDTRANS_SERVER_KEY` belum di-set atau pesanan sudah dibayar |
| Webhook 403 | Signature tidak cocok; pastikan server key yang dipakai sama dengan saat membuat transaksi |
| Pembayaran sukses tetapi order tetap `awaitingPayment` | URL notifikasi Midtrans belum diarahkan ke `midtransWebhook`, atau function belum di-deploy |
| Dompet tidak bertambah | `courierId` kosong, tarif/titik tidak valid, atau trigger belum ter-deploy |
| `failed-precondition` "Jarak pengiriman melebihi..." | Titik peta terlalu jauh; server menolak tarif di luar batas 30 km |
| Saldo bertambah dua kali | Seharusnya tidak terjadi karena ledger `earning_{orderId}` idempoten; periksa duplikasi manual |

## 7. Catatan keamanan

- Server key tidak pernah dikirim ke aplikasi.
- Client tidak boleh menulis `payments`, `wallets`, atau
  `wallet_transactions`.
- Harga final dihitung ulang di server dari titik peta saat membuat pembayaran
  Midtrans dan saat COD diselesaikan. Nominal Midtrans/dompet tidak memakai
  `price` mentah dari client.
- Webhook memverifikasi signature, kecocokan `order_id`, dan nominal
  `gross_amount` terhadap dokumen `payments`.
- Kurir tidak dapat mengubah `price`/alamat setelah order dibuat (rules).
- Refund otomatis belum tersedia. Bila pesanan gateway dibatalkan tetapi
  pembayaran tetap settle di Midtrans, admin harus memproses refund manual;
  webhook hanya menandai `paymentStatus` menjadi `paid`.
- Untuk produksi, batasi `maxInstances`, aktifkan App Check, dan gunakan
  secret manager.
