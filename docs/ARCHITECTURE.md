# Arsitektur — Jeneponto Kurir

Dokumen ini menetapkan arsitektur aplikasi kurir multi-role (Customer / Kurir / Admin)
wilayah Jeneponto. Basis: kode yang **sudah ada** di repo (Flutter + Clean Architecture +
BLoC + go_router + Firebase), bukan usulan greenfield.

Versi: 1.0 — 2026-10-27
Status basis kode: **belum compile**. `lib/core/di/injector.dart` dan `lib/core/router/app_router.dart`
mengimpor 20 file yang belum ada di disk (lihat §10).

---

## 1. Prinsip yang Dipakai

| # | Prinsip | Konsekuensi konkret |
|---|---|---|
| 1 | Clean Architecture per fitur | `domain` tidak boleh impor `data`, `presentation`, atau Firebase |
| 2 | Feature-first, bukan layer-first | Semua file fitur `order` ada di `features/order/**` |
| 3 | Satu arah dependensi | `presentation → domain ← data` |
| 4 | BLoC sebagai satu-satunya state holder | Tidak ada `setState` untuk state bisnis; `ValueNotifier` hanya untuk UI lokal |
| 5 | Firebase = infrastruktur, bukan domain | Tipe `Timestamp`, `DocumentSnapshot`, `FirebaseUser` tidak boleh bocor ke domain |
| 6 | Uang & status pesanan = server-authoritative | Client tidak pernah jadi sumber kebenaran tarif maupun transisi status |
| 7 | Failure berbahasa Indonesia, exception berbahasa teknis | `Either<Failure, T>` di repository, `Exception` hanya di data source |

Prinsip 1–5, 7 sudah konsisten di kode saat ini (lihat `AuthRemoteDataSourceImpl` yang menelan
`FirebaseAuthException` → `AuthException`). Prinsip 6 belum ada karena belum ada order layer.

---

## 2. Peta Lapisan

```
┌──────────────────────────────────────────────────────────────────────┐
│  PRESENTATION                                                        │
│  pages/  widgets/  bloc/            (Event → State, UI murni)         │
│  • AppRouter + redirect guard        • BlocProvider per halaman       │
└───────────────────────────┬──────────────────────────────────────────┘
                            │ memanggil (via GetIt)
┌───────────────────────────▼──────────────────────────────────────────┐
│  DOMAIN                                                              │
│  entities/    repositories/ (abstract)                               │
│  • OrderEntity, UserEntity, OrderStatus, CourierProfileEntity        │
│  • OrderRepository, AuthRepository, CourierRepository, AdminRepository│
│  • PriceCalculator (pure, sudah ada)                                 │
│  ZERO dependency: Flutter, Firebase, dartz-only untuk Either         │
└───────────────────────────▲──────────────────────────────────────────┘
                            │ implements
┌───────────────────────────┴──────────────────────────────────────────┐
│  DATA                                                                │
│  datasources/ (FirebaseAuth, Firestore, Storage, Messaging)          │
│  models/      (extends Entity, fromMap/toMap/fromDoc)                │
│  repositories/ (Exception → Failure, Map → Entity)                   │
└───────────────────────────┬──────────────────────────────────────────┘
                            │
┌───────────────────────────▼──────────────────────────────────────────┐
│  INFRASTRUCTURE                                                      │
│  Firebase Auth · Firestore · Storage · FCM · Cloud Functions (fase 2)│
│  core/services: LocationService · NotificationService · StorageService│
└──────────────────────────────────────────────────────────────────────┘
```

Aturan penegakan (bisa dijadikan lint kustom / review checklist):

- `lib/features/*/domain/**` **tidak boleh** mengimpor `cloud_firestore`, `firebase_auth`,
  `flutter/material`, atau `../data/**`.
- `lib/features/*/data/**` **tidak boleh** mengimpor `../presentation/**`.
- `Bloc` hanya boleh bergantung pada `Repository` (abstract), bukan `DataSource`.
- `PriceCalculator` **hanya** dipakai untuk estimasi UI; harga final dihitung ulang di server
  (Firestore Rules + Cloud Function), lihat §7.

---

## 3. Struktur Direktori Target

```
lib/
├── main.dart                      # bootstrap Firebase + DI
├── app.dart                       # MaterialApp.router, AuthBloc global
├── core/
│   ├── config/firebase_options.dart
│   ├── constants/
│   │   ├── app_constants.dart          # tarif, label, support
│   │   ├── firestore_collections.dart   # nama collection (single source)
│   │   └── storage_paths.dart           # path Firebase Storage
│   ├── di/injector.dart
│   ├── error/{failures,exceptions}.dart
│   ├── router/{app_router,go_router_refresh_stream}.dart
│   ├── services/                        # BARU
│   │   ├── location_service.dart         # stream posisi + throttle
│   │   ├── notification_service.dart      # FCM token, handler, routing
│   │   └── storage_service.dart           # upload avatar / foto bukti
│   ├── theme/{app_theme,app_colors}.dart
│   ├── utils/{validators,formatters,price_calculator}.dart
│   └── widgets/{app_button,app_text_field,empty_state,setup_required_app}.dart
└── features/
    ├── auth/            ✅ selesai (data, domain, presentation)
    ├── splash/          ⬜ dirujuk router, file belum ada
    ├── home/            ⬜ HomeShell + customer home
    ├── order/           ⬜ buat pesanan, daftar pesanan, detail, tracking
    ├── courier/         ⬜ dashboard, job board, update status
    ├── admin/           ⬜ monitoring order, kelola user & tarif
    ├── profile/         ⬜ profil, alamat tersimpan, logout
    ├── tracking/        ⬜ peta + timeline status (fase 2)
    └── notification/    ⬜ inbox in-app (fase 2)

Pola tiap fitur (wajib seragam dengan `auth`):
features/<fitur>/
├── data/
│   ├── datasources/<fitur>_remote_data_source.dart   # abstract + Impl
│   ├── models/<nama>_model.dart                      # extends Entity
│   └── repositories/<fitur>_repository_impl.dart
├── domain/
│   ├── entities/<nama>_entity.dart
│   └── repositories/<fitur>_repository.dart          # abstract, Either<>
└── presentation/
    ├── bloc/{<fitur>_bloc,<fitur>_event,<fitur>_state}.dart
    ├── pages/
    └── widgets/
```

Catatan: repo ini **tidak** memakai lapisan `usecases/`. BLoC memanggil repository langsung.
Pertahankan pola itu agar konsisten; tambahkan `usecases/` hanya bila satu aksi butuh
orkestrasi >1 repository (mis. `CreateOrder` = hitung tarif + simpan order + kirim notifikasi).

---

## 4. Alur Data (Request)

Contoh: customer membuat pesanan.

```
CreateOrderPage
  └─ context.read<OrderBloc>().add(OrderCreateRequested(input))
       └─ OrderBloc (presentation)
            └─ OrderRepository.create(input)            [domain, abstract]
                 └─ OrderRepositoryImpl                 [data]
                      ├─ PriceCalculator.estimate()      (validasi lokal, bukan harga final)
                      ├─ OrderRemoteDataSource.create()  (Firestore write)
                      └─ return Either<Failure, OrderEntity>
            └─ emit(OrderCreateSuccess(order))
  └─ BlocListener → context.go('/orders/${order.id}') → SnackBar
```

Konvensi state (mengikuti `auth_state.dart`: satu class state + `status` enum):

```dart
enum OrderStatusView { initial, loading, success, failure }
class OrderState {
  final OrderStatusView status;
  final List<OrderEntity> orders;
  final OrderEntity? selected;
  final String? message;
}
```

Jangan satu class state per kejadian (`OrderLoading`, `OrderSuccess`, ...) — repo ini sudah
memilih model `status` + data opsional, konsisten dipakai di semua BLoC baru.

---

## 5. Model Domain

### 5.1 `OrderEntity`

```dart
enum OrderStatus {
  pending('Menunggu kurir'),      // dibuat customer, belum ada kurir
  accepted('Kurir ditugaskan'),   // kurir ambil job
  pickedUp('Paket diambil'),      // bukti pickup + foto
  delivering('Dalam perjalanan'), // opsional: kurir bergerak
  delivered('Terkirim'),          // bukti antar + foto + nama penerima
  cancelled('Dibatalkan'),        // customer/admin sebelum pickup
  failed('Gagal antar');          // kurir lapor gagal (penerima tidak ada)

  const OrderStatus(this.label);
  final String label;
  static OrderStatus fromString(String? v) => ...;
  bool get isTerminal => this == delivered || this == cancelled || this == failed;
}
```

Field minimum:

| Field | Tipe | Catatan |
|---|---|---|
| `id` | String | doc id |
| `code` | String | `JK-YYMMDD-XXXX`, unik, untuk dibaca manusia |
| `customerId` | String | = `request.auth.uid` (dipaksa rules) |
| `courierId` | String? | null saat `pending` |
| `status` | String | enum name |
| `pickup` | `Address` (nama, phone, alamat, lat, lng, notes) | |
| `dropoff` | `Address` | |
| `distanceKm` | double | snapshot saat order dibuat |
| `fare` | int | dihitung **server-side** (fase 2), client hanya menampilkan estimasi |
| `paymentMethod` | `cash` \| `transfer` \| `ewallet` | fase 1: cash/COD saja |
| `itemCategory`, `itemNotes`, `weightKg` | | kategori untuk filter kurir |
| `createdAt`, `acceptedAt`, `pickedUpAt`, `deliveredAt` | Timestamp | audit |
| `cancelledReason` | String? | |
| `rating` | int? | 1–5 setelah delivered |

`Address` sebagai value object di `domain/entities/address.dart` (bukan Map mentah) supaya
serialisasi ke Firestore hanya terjadi di `OrderModel`.

### 5.2 `CourierProfileEntity`

Dokumen terpisah `couriers/{uid}` — jangan menumpuk data operasional kurir di `users/{uid}`
karena rules `users` harus bisa dibaca pemiliknya saja, sementara `couriers` perlu dibaca publik
(menampilkan nama + rating kurir ke customer).

| Field | Tipe | Catatan |
|---|---|---|
| `uid`, `name`, `phone`, `photoUrl` | | denormalisasi untuk list |
| `isOnline` | bool | toggle manual |
| `isVerified` | bool | **hanya admin** yang boleh set true |
| `vehicle` | `motor` \| `mobil` | |
| `activeOrderId` | String? | satu kurir = satu order aktif (aturan bisnis) |
| `completedOrders`, `ratingAvg`, `ratingCount` | num | agregat, diupdate via transaction |
| `lastLocation` | GeoPoint | throttle 20–30 s |
| `lastLocationAt` | Timestamp | untuk deteksi kurir "stale" |
| `serviceArea` | List<String> | kecamatan di Jeneponto (Bangkalaloe, Batang, Kelara, …) |

---

## 6. Skema Firestore

```
users/{uid}
  └─ (dokumen profil; role: customer|courier|admin)

couriers/{uid}                     # profil operasional + lokasi terakhir
orders/{orderId}
  ├─ tracking/{pointId}            # { lat, lng, at, courierId, heading, speed }
  └─ events/{eventId}              # audit log: { from, to, by, at, note }
users/{uid}/addresses/{addressId}  # alamat tersimpan customer
config/app                         # { baseFare, perKmFare, minDistanceKm, roundingStep,
                                   #   commissionPct, isServiceOpen }
meta/counters/{key}                # { value } untuk kode order harian
payouts/{payoutId}                 # fase 3: settlement kurir
```

### 6.1 Index komposit yang wajib dibuat

| Collection | Fields | Dipakai untuk |
|---|---|---|
| `orders` | `customerId` ASC, `createdAt` DESC | riwayat pesanan customer |
| `orders` | `courierId` ASC, `status` ASC, `createdAt` DESC | job aktif kurir |
| `orders` | `status` ASC, `createdAt` ASC | job board (`pending`, urut terlama) |
| `orders` | `status` ASC, `createdAt` DESC | dashboard admin |
| `couriers` | `isOnline` ASC, `serviceArea` ARRAY, `lastLocationAt` DESC | pencarian kurir terdekat |
| `orders/{id}/tracking` | `at` ASC | replay rute |

Semua query list **wajib** `limit()` + paginasi cursor (`startAfterDocument`), bukan
`StreamBuilder` tanpa batas — biaya baca Firestore adalah pengeluaran utama aplikasi ini.

### 6.2 Denormalisasi yang disengaja

- `orders` menyimpan `customerName`, `courierName`, `courierPhone` (string) → list admin/kurir
  tidak perlu N+1 read.
- Nama di `orders` adalah **snapshot**; perubahan profil tidak menulis ulang order lama.
- `couriers.completedOrders`/`ratingAvg` = agregat; sumber kebenaran tetap koleksi `orders`.

---

## 7. Integritas: Rules + Functions

### 7.1 Security Rules (garis besar)

```js
rules_version = '2';
service cloud.firestore {
  match /databases/{db}/documents {

    function signedIn() { return request.auth != null; }
    function uid() { return request.auth.uid; }
    function role() { return get(/databases/$(db)/documents/users/$(uid())).data.role; }
    function isAdmin() { return signedIn() && role() == 'admin'; }

    // users: baca/tulis milik sendiri; role TIDAK boleh diubah sendiri
    match /users/{userId} {
      allow read: if signedIn() && (uid() == userId || isAdmin());
      allow create: if uid() == userId
                    && request.resource.data.role in ['customer', 'courier']
                    && !('isVerified' in request.resource.data);
      allow update: if uid() == userId
                    && request.resource.data.role == resource.data.role;
      allow delete: if isAdmin();
    }

    // couriers: publik boleh baca field tampilan; tulis hanya pemilik, verifikasi hanya admin
    match /couriers/{cid} {
      allow read: if signedIn();
      allow create, update: if uid() == cid
                            && request.resource.data.isVerified == resource.data.isVerified;
      allow update: if isAdmin();
    }

    match /orders/{orderId} {
      function isParticipant() {
        return signedIn() &&
          (resource.data.customerId == uid() || resource.data.courierId == uid());
      }

      allow read: if isParticipant() || isAdmin();

      // Customer hanya boleh membuat order untuk dirinya, status awal pending,
      // dan TIDAK boleh menentukan fare sendiri.
      allow create: if signedIn()
                    && request.resource.data.customerId == uid()
                    && request.resource.data.status == 'pending'
                    && request.resource.data.courierId == null
                    && request.resource.data.fare is int;

      // Customer: batalkan hanya saat masih pending.
      allow update: if signedIn()
                    && resource.data.customerId == uid()
                    && resource.data.status == 'pending'
                    && request.resource.data.diff(resource.data).affectedKeys()
                         .hasOnly(['status', 'cancelledReason'])
                    && request.resource.data.status == 'cancelled';

      // Kurir: klaim job kosong atau update order miliknya; field terbatas.
      allow update: if signedIn()
                    && request.resource.data.diff(resource.data).affectedKeys()
                         .hasOnly(['courierId','status','courierName','courierPhone',
                                   'acceptedAt','pickedUpAt','deliveredAt','rating',
                                   'pickupProofUrl','dropoffProofUrl','recipientName',
                                   'cancelledReason'])
                    && role() == 'courier';

      allow update: if isAdmin();

      match /tracking/{pointId} {
        allow read: if isParticipant() || isAdmin();
        allow create: if signedIn()
                      && get(/databases/$(db)/documents/orders/$(orderId)).data.courierId == uid();
      }

      match /events/{eventId} {
        allow read: if isParticipant() || isAdmin();
        allow create: if isAdmin();   // audit log ditulis Cloud Function, bukan client
      }
    }

    match /config/{docId} {
      allow read: if true;
      allow write: if isAdmin();
    }

    match /meta/{docId} { allow read, write: if false; }  // hanya Admin SDK
  }
}
```

Yang **sengaja** tidak diizinkan untuk client:

- Menulis `fare` setelah order dibuat, `isVerified` kurir, dan `events` (audit).
- Membaca `users/{uid}` milik orang lain — data ponsel/email customer tidak boleh bocor
  ke kurir lain; yang dibutuhkan kurir hanya `pickup`/`dropoff` dari order yang ia pegang.

### 7.2 Kenapa Cloud Function dibutuhkan (fase 2)

| Masalah | Client-only | Dengan Functions |
|---|---|---|
| Dua kurir klaim satu order | Perlu transaksi; bisa diakali lewat REST | Callable `claimOrder` transaksional + rate limit |
| `fare` bisa dimanipulasi | Rules hanya cek tipe `int` | `onOrderCreate` hitung ulang dari tarif `config/app`, tolak selisih |
| Rating pemain ganda | Tidak terverifikasi | Validasi status `delivered` + `courierId == uid` |
| Agregat `ratingAvg` | Race write | `onOrderUpdate` transaction |
| Kirim FCM saat status berubah | Client bisa spam | Trigger `onOrderUpdate` → kirim ke lawan transaksi |
| Kode order unik | Collision | Transaction pada `meta/counters` (Admin SDK) |

Aturan keras: **harga final = server**. `PriceCalculator` di client hanya estimasi untuk UI.
Bila keduanya beda, order ditolak saat create.

---

## 8. State Machine Pesanan

```
                 customer buat
                      │
                      ▼
              ┌──────────────┐   kurir klaim (tx)   ┌──────────────┐
              │   pending    │─────────────────────▶│   accepted   │
              └──────┬───────┘                      └──────┬───────┘
       customer/admin│ cancel                              │ bukti pickup + foto
                     ▼                                     ▼
              ┌──────────────┐                      ┌──────────────┐
              │  cancelled   │◀───── admin ─────────│   pickedUp    │
              └──────────────┘                      └──────┬───────┘
                                                           │
                                                    ┌──────▼───────┐
                                                    │  delivering  │ (opsional, fase 2)
                                                    └──────┬───────┘
                                            sukses / gagal │
                                     ┌─────────────────────┴──────────┐
                                     ▼                                ▼
                              ┌──────────────┐                 ┌──────────────┐
                              │  delivered   │                 │    failed    │
                              └──────────────┘                 └──────────────┘
```

| Transisi | Aktor | Syarat | Efek samping |
|---|---|---|---|
| `pending → accepted` | kurir | `courierId == null`, `isVerified`, `isOnline`, `activeOrderId == null` | set `courierId`, `courier*` snapshot, `acceptedAt`, `couriers.activeOrderId` |
| `accepted → pickedUp` | kurir pemegang | `pickupProofUrl != null` | `pickedUpAt`, notifikasi customer |
| `pickedUp → delivering` | kurir | fase 2 (GPS aktif) | tracking points mengalir |
| `delivering/pickedUp → delivered` | kurir pemegang | `dropoffProofUrl != null`, `recipientName != null` | `deliveredAt`, `couriers.activeOrderId = null`, agregat selesai, minta rating |
| `delivering → failed` | kurir | alasan wajib | `activeOrderId = null`, order masuk antrean admin |
| `pending → cancelled` | customer/admin | belum pickup | `cancelledReason` |

Implementasi klaim wajib transaksi:

```dart
// data/datasources/order_remote_data_source.dart
Future<OrderModel> claim(String orderId, UserEntity courier) {
  final orderRef = _db.collection(FirestoreCollections.orders).doc(orderId);
  final courierRef = _db.collection(FirestoreCollections.couriers).doc(courier.uid);

  return _db.runTransaction((tx) async {
    final orderSnap = await tx.get(orderRef);
    if (!orderSnap.exists) throw const ServerException('Pesanan tidak ditemukan.');

    final data = orderSnap.data()!;
    if (data['status'] != 'pending') {
      throw const ServerException('Pesanan sudah diambil kurir lain.');
    }
    if (data['courierId'] != null) {
      throw const ServerException('Pesanan sudah diambil kurir lain.');
    }

    tx.update(orderRef, {
      'courierId': courier.uid,
      'courierName': courier.name,
      'courierPhone': courier.phone,
      'status': 'accepted',
      'acceptedAt': FieldValue.serverTimestamp(),
    });
    tx.update(courierRef, {
      'activeOrderId': orderId,
      'name': courier.name,
      'phone': courier.phone,
    });
    return orderSnap;  // dibaca ulang / dipetakan ke model
  });
}
```

---

## 9. Matriks Peran

| Kapabilitas | Customer | Kurir | Admin |
|---|---|---|---|
| Buat order | ✅ | – | – |
| Batalkan order (`pending`) | ✅ | – | ✅ |
| Klaim order | – | ✅ (verified, online) | – |
| Ubah status order | – | ✅ (miliknya) | ✅ |
| Lihat tracking order | ✅ (miliknya) | ✅ (miliknya) | ✅ semua |
| Lihat semua order | – | job board `pending` + miliknya | ✅ |
| Verifikasi kurir | – | – | ✅ |
| Ubah tarif `config/app` | – | – | ✅ |
| Baca `users` orang lain | – | – | ✅ |
| Rating kurir | ✅ (setelah `delivered`) | – | – |

Role disimpan di `users/{uid}.role` (sumber kebenaran untuk rules) **dan** di custom claim
Firebase Auth (`role`) untuk pengecekan di client/Function. Custom claim hanya diset oleh
Cloud Function admin; client tidak boleh mengubahnya.

---

## 10. Gap Basis Kode Saat Ini

File yang **diimpor tetapi tidak ada** → `flutter analyze` gagal:

| Diimpor oleh | File hilang |
|---|---|
| `core/di/injector.dart` | `features/courier/presentation/bloc/courier_order_bloc.dart` |
| | `features/order/data/datasources/order_remote_data_source.dart` |
| | `features/order/data/repositories/order_repository_impl.dart` |
| | `features/order/domain/repositories/order_repository.dart` |
| | `features/order/presentation/bloc/order_bloc.dart` |
| | `features/admin/presentation/bloc/admin_bloc.dart` |
| `core/router/app_router.dart` | `features/splash/presentation/splash_page.dart` |
| | `features/home/presentation/home_shell.dart` |
| | `features/home/presentation/pages/customer_home_page.dart` |
| | `features/order/presentation/pages/create_order_page.dart` |
| | `features/order/presentation/pages/orders_page.dart` |
| | `features/courier/presentation/pages/courier_dashboard_page.dart` |
| | `features/admin/presentation/pages/admin_dashboard_page.dart` |
| | `features/profile/presentation/pages/profile_page.dart` |

Selain itu:

1. **Router belum punya guard peran.** `_redirect` hanya membedakan login/belum. Perlu
   `homePath` berbeda per role: `/home/customer`, `/home/courier`, `/home/admin`, dan
   blokir akses kurir ke halaman admin.
2. **Rute detail/tracking belum ada** — belum ada `path: '/orders/:id'`.
3. **Deep link FCM belum ada** — `notification_service.dart` harus memetakan payload
   (`orderId`, `type`) → `router.go('/orders/$id')`.
4. **Tidak ada `config/app`** — tarif masih konstanta compile-time (`AppConstants`).
   Untuk MVP boleh, tetapi pindahkan ke Firestore sebelum rilis agar admin bisa ubah tarif
   tanpa update aplikasi.
5. **Tidak ada lapisan cache/offline.** Firestore sudah offline-capable untuk read; untuk
   kurir di area sinyal lemah, aktifkan
   `FirebaseFirestore.instance.settings = Settings(persistenceEnabled: true, cacheSizeBytes: 40MB)`
   dan tampilkan indikator "data tertunda" bila `pendingWrites > 0`.

---

## 11. Peta Rute

```dart
'/splash'                        SplashPage           (cek sesi + role)
'/login' '/register'             Auth                 (redirect bila sudah masuk)
'/home/customer'                 CustomerHomePage
'/home/customer/orders'          OrdersPage
'/home/customer/orders/create'   CreateOrderPage
'/orders/:id'                    OrderDetailPage      (semua role, guard kepemilikan)
'/orders/:id/track'              TrackingPage         (fase 2)
'/home/courier'                  CourierDashboardPage (verified only)
'/home/courier/jobs'             JobBoardPage
'/home/admin'                    AdminDashboardPage   (admin only)
'/home/admin/users'              ManageUsersPage
'/profile'                       ProfilePage
```

Guard tunggal di `_redirect`:

```dart
// Ringkas: status auth → role → area
if (status != authenticated) return isAuthRoute ? null : loginPath;

final role = authBloc.state.user?.role;
final areas = {
  UserRole.customer: '/home/customer',
  UserRole.courier:  '/home/courier',
  UserRole.admin:    '/home/admin',
};
final area = areas[role]!;

if (isSplash || isAuthRoute) return area;
if (location.startsWith('/home/admin') && role != UserRole.admin) return area;
if (location.startsWith('/home/courier') && role != UserRole.courier) return area;
if (location.startsWith('/home/customer') && role != UserRole.customer) return area;
return null;
```

Guard di client hanya untuk UX. Otorisasi sebenarnya tetap di Security Rules — jangan
pernah mengandalkan `_redirect` sebagai kontrol keamanan.

---

## 12. Tracking Lokasi (Fase 2)

Strategi hemat biaya + hemat baterai:

1. `LocationService` membungkus `geolocator` (masih dikomentari di `pubspec.yaml`).
2. Kirim titik hanya bila **bergerak > 30 m** ATAU **> 30 detik** sejak titik terakhir.
3. Tulis ke `couriers/{uid}.lastLocation` (1 write) setiap 30 s, dan ke
   `orders/{id}/tracking` setiap 60 s (riwayat rute, untuk replay).
4. Berhenti total saat `activeOrderId == null` — tidak ada tracking saat idle (privasi + biaya).
5. Retensi: hapus `tracking` > 30 hari via scheduled Function + TTL policy.
6. Tampilkan ke customer dengan `StreamBuilder` pada `orders/{id}` (posisi terakhir kurir),
   bukan stream subcollection — 1 listener, bukan N.
7. Izin: `whileInUse` untuk MVP. `background` hanya bila kurir toggle "mode aktif" dan
   wajib menampilkan notifikasi persisten (kebijakan Play Store).

---

## 13. Notifikasi (FCM)

| Event | Penerima | Payload | Aksi tap |
|---|---|---|---|
| Order baru di area kurir | kurir `isOnline` | `type: order_available` | `/home/courier/jobs` |
| Kurir klaim | customer | `type: courier_assigned` | `/orders/{id}` |
| Paket diambil | customer | `type: picked_up` | `/orders/{id}` |
| Terkirim | customer | `type: delivered` | `/orders/{id}?rate=1` |
| Dibatalkan | kurir pemegang | `type: cancelled` | `/orders/{id}` |
| Kurir diverifikasi | kurir | `type: verified` | `/home/courier` |

- Token disimpan di `users/{uid}.fcmTokens: [token...]` (array, multi-device) via
  `NotificationService`; hapus token saat `onTokenRefresh`/logout.
- Kirim dari Cloud Function `onOrderUpdate` (bukan dari client) agar tidak bisa dispam.
- Topik: `couriers_<kecamatan>` untuk broadcast job board — hindari query semua kurir online
  per order.

---

## 14. Tarif & Settlement

Rumus saat ini (`PriceCalculator`): `ceil((8000 + max(1 km, d) × 2500) / 500) × 500`.

Fase 1 (client + rules): fare disimpan saat create; aturan bisnis:
- `distanceKm` dibatasi 0.5–30 km (validasi `Validators` + rules).
- Pembayaran **cash on delivery** saja.
- Snapshot tarif ke order (jangan baca `config/app` ulang saat menampilkan riwayat).

Fase 2 (Functions): `onOrderCreate` hitung ulang; jika `|fare_client − fare_server| > 0` →
tandai `fareMismatch` dan tolak/override. Komisi `commissionPct` disimpan di
`payouts/{payoutId}` (agregat per kurir per hari), dihitung saat `delivered`.

Jangan menyimpan saldo kurir di client; seluruh angka uang berasal dari server.

---

## 15. Peta Jalan Implementasi

| Fase | Fokus | Definisi selesai |
|---|---|---|
| **0** | Perbaiki compile | Semua file di §10 ada (stub halaman + BLoC kosong), `flutter analyze` bersih, app jalan sampai login |
| **1** | Core transaksi | `OrderEntity`, repository, create/list/detail, claim transaksional, state machine 5 status, rules + index, job board kurir |
| **2** | Operasional | `couriers` profile, verifikasi admin, bukti foto (Storage), FCM, guard peran, dashboard admin |
| **3** | Peta & settlement | `geolocator` + `google_maps_flutter`, tracking rute, rating, payout, laporan harian |
| **4** | Skala & keamanan | Cloud Functions (fare server-side, anti-double-claim, audit), App Check, rate limit, monitoring Crashlytics |

Definition of done global: setiap fitur baru wajib punya (a) entity domain bebas Firebase,
(b) model `fromMap/toMap`, (c) repository `Either<Failure, T>`, (d) BLoC dengan `status` enum,
(e) rules + index Firestore, (f) minimal satu `bloc_test`.

---

## 16. Keputusan Arsitektur (ADR Ringkas)

| # | Keputusan | Alasan | Konsekuensi |
|---|---|---|---|
| ADR-01 | Firestore langsung dari client, Functions menyusul | waktu rilis, biaya awal rendah | integritas bergantung rules; pindah ke Functions di fase 4 |
| ADR-02 | Tanpa `usecases/` | aksi masih sederhana; BLoC → repository cukup | tambah `usecases/` bila logika lintas-repo muncul |
| ADR-03 | `price_calculator` di `core/utils` | dipakai order + admin + estimasi | harus direplikasi di server; duplikasi disengaja dan diuji silang |
| ADR-04 | `couriers` terpisah dari `users` | `users` privat, `couriers` semi-publik | dua dokumen per kurir; sinkronisasi nama via Function |
| ADR-05 | Satu order aktif per kurir | model bisnis kurir lokal | butuh transaksi + `activeOrderId` sebagai kunci |
| ADR-06 | `AuthBloc` singleton | router butuh stream reaktif | BLoC lain `registerFactory` per halaman |
| ADR-07 | Enum `status` + state tunggal | konsisten dengan `AuthState` | hindari ledakan class state |

---

*Dokumen hidup. Ubah lewat PR disertai alasan; setiap perubahan skema Firestore wajib
menyertakan migrasi + pembaruan `docs/firestore.rules` dan daftar index.*
