/**
 * Seed data demo untuk Firebase Emulator Suite.
 *
 * Jalankan setelah emulator hidup:
 *   node tool/seed_emulator.mjs
 *
 * Akun:
 *   customer@demo.test / password123
 *   courier@demo.test  / password123
 *   admin@demo.test    / password123
 */

const AUTH = 'http://127.0.0.1:9099';
const FIRESTORE = 'http://127.0.0.1:8080';
const PROJECT = 'demo-jeneponto';
const API_KEY = 'demo-api-key';
const PASSWORD = 'password123';

const dbPath = (collection, id) =>
  `${FIRESTORE}/v1/projects/${PROJECT}/databases/(default)/documents/${collection}/${id}`;

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

async function waitFor(url, label) {
  for (let i = 0; i < 60; i += 1) {
    try {
      const response = await fetch(url);
      if (response.status < 500) return;
    } catch (_) {
      // Emulator belum siap.
    }
    await sleep(1000);
  }
  throw new Error(`${label} tidak merespons.`);
}

async function authUser(email, displayName) {
  const signUp = await fetch(
    `${AUTH}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=${API_KEY}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email,
        password: PASSWORD,
        displayName,
        returnSecureToken: true,
      }),
    },
  );

  if (signUp.ok) return signUp.json();

  const signIn = await fetch(
    `${AUTH}/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${API_KEY}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email,
        password: PASSWORD,
        returnSecureToken: true,
      }),
    },
  );

  if (!signIn.ok) {
    throw new Error(`Gagal membuat/masuk akun ${email}: ${await signIn.text()}`);
  }
  return signIn.json();
}

const str = (value) => ({ stringValue: value });
const int = (value) => ({ integerValue: String(value) });
const dbl = (value) => ({ doubleValue: value });
const bool = (value) => ({ booleanValue: value });
const ts = (value) => ({ timestampValue: value });
const map = (value) => ({ mapValue: { fields: value } });
const nil = () => ({ nullValue: null });

async function putDoc(collection, id, fields) {
  const response = await fetch(dbPath(collection, id), {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      Authorization: 'Bearer owner',
    },
    body: JSON.stringify({ fields }),
  });
  if (!response.ok) {
    throw new Error(
      `Gagal menulis ${collection}/${id}: ${await response.text()}`,
    );
  }
}

function fare(distanceKm) {
  const baseFare = 8000;
  const perKmFare = 2500;
  const minimumDistanceKm = 1;
  const step = 500;
  const billable = Math.max(distanceKm, minimumDistanceKm);
  const distanceCharge = Math.round(billable * perKmFare);
  const raw = baseFare + distanceCharge;
  const total = Math.ceil(raw / step) * step;
  return {
    baseFare,
    perKmFare,
    distanceCharge,
    roundingAdjustment: total - raw,
    total,
    billable,
    minimumApplied: distanceKm < minimumDistanceKm,
  };
}

function address({
  label,
  address,
  district,
  lat,
  lng,
  contactName,
  contactPhone,
}) {
  return {
    label: str(label),
    address: str(address),
    district: str(district),
    lat: dbl(lat),
    lng: dbl(lng),
    contactName: str(contactName),
    contactPhone: str(contactPhone),
    notes: str(''),
  };
}

async function main() {
  console.log('Menunggu emulator Auth dan Firestore...');
  await waitFor(`${AUTH}/`, 'Auth emulator');
  await waitFor(`${FIRESTORE}/`, 'Firestore emulator');

  const customer = await authUser('customer@demo.test', 'Budi Santoso');
  const courier = await authUser('courier@demo.test', 'Andi Pratama');
  const admin = await authUser('admin@demo.test', 'Admin Jeneponto');

  const customerId = customer.localId;
  const courierId = courier.localId;
  const adminId = admin.localId;

  const users = [
    {
      uid: customerId,
      email: 'customer@demo.test',
      name: 'Budi Santoso',
      phone: '081234567890',
      role: 'customer',
    },
    {
      uid: courierId,
      email: 'courier@demo.test',
      name: 'Andi Pratama',
      phone: '081298765432',
      role: 'courier',
    },
    {
      uid: adminId,
      email: 'admin@demo.test',
      name: 'Admin Jeneponto',
      phone: '081200000000',
      role: 'admin',
    },
  ];

  for (const user of users) {
    await putDoc('users', user.uid, {
      uid: str(user.uid),
      email: str(user.email),
      name: str(user.name),
      phone: str(user.phone),
      role: str(user.role),
      photoUrl: nil(),
      createdAt: ts('2026-10-20T08:00:00Z'),
    });
  }

  const orders = [
    {
      id: 'demo-order-1',
      code: 'JK-DEMO-001',
      status: 'delivered',
      paymentMethod: 'cod',
      paymentStatus: 'paid',
      distanceKm: 4.2,
      createdAt: '2026-10-26T08:15:00Z',
      updatedAt: '2026-10-26T10:05:00Z',
      pickup: {
        label: 'Penjemputan',
        address: 'Jl. Sultan Hasanuddin No. 12, Binamu',
        district: 'Binamu',
        lat: -5.6791,
        lng: 119.7352,
        contactName: 'Budi Santoso',
        contactPhone: '081234567890',
      },
      dropoff: {
        label: 'Tujuan',
        address: 'Pasar Sentral Binamu, Blok A',
        district: 'Binamu',
        lat: -5.6712,
        lng: 119.7425,
        contactName: 'Siti Rahma',
        contactPhone: '081255566677',
      },
      category: 'Paket',
      weightKg: 2,
      notes: 'Titip di pos pasar.',
      courier: true,
      deliveredAt: '2026-10-26T10:05:00Z',
    },
    {
      id: 'demo-order-2',
      code: 'JK-DEMO-002',
      status: 'pending',
      paymentMethod: 'cod',
      paymentStatus: 'unpaid',
      distanceKm: 3.4,
      createdAt: '2026-10-27T09:30:00Z',
      updatedAt: '2026-10-27T09:30:00Z',
      pickup: {
        label: 'Penjemputan',
        address: 'Jl. Poros Jeneponto-Takalar KM 4',
        district: 'Tamalatea',
        lat: -5.6431,
        lng: 119.6712,
        contactName: 'Budi Santoso',
        contactPhone: '081234567890',
      },
      dropoff: {
        label: 'Tujuan',
        address: 'Rumah Duka, Lingkungan Bontoa',
        district: 'Tamalatea',
        lat: -5.6528,
        lng: 119.6847,
        contactName: 'Hasan Basri',
        contactPhone: '081277788899',
      },
      category: 'Makanan',
      weightKg: 3,
      notes: 'Tolong jaga agar tetap hangat.',
    },
    {
      id: 'demo-order-3',
      code: 'JK-DEMO-003',
      status: 'awaitingPayment',
      paymentMethod: 'midtrans',
      paymentStatus: 'unpaid',
      distanceKm: 5.1,
      createdAt: '2026-10-28T07:45:00Z',
      updatedAt: '2026-10-28T07:45:00Z',
      pickup: {
        label: 'Penjemputan',
        address: 'Jl. Kemakmuran No. 8, Bontoramba',
        district: 'Bontoramba',
        lat: -5.6234,
        lng: 119.7441,
        contactName: 'Budi Santoso',
        contactPhone: '081234567890',
      },
      dropoff: {
        label: 'Tujuan',
        address: 'SMP Negeri 2 Bontoramba',
        district: 'Bontoramba',
        lat: -5.6118,
        lng: 119.7569,
        contactName: 'Ibu Guru Rina',
        contactPhone: '081299900011',
      },
      category: 'Dokumen',
      weightKg: 1,
      notes: 'Dokumen sekolah, jangan dilipat.',
    },
    {
      id: 'demo-order-4',
      code: 'JK-DEMO-004',
      status: 'accepted',
      paymentMethod: 'cod',
      paymentStatus: 'unpaid',
      distanceKm: 2.6,
      createdAt: '2026-10-28T06:20:00Z',
      updatedAt: '2026-10-28T06:35:00Z',
      pickup: {
        label: 'Penjemputan',
        address: 'Jl. Bhayangkara No. 21, Batang',
        district: 'Batang',
        lat: -5.5982,
        lng: 119.7428,
        contactName: 'Budi Santoso',
        contactPhone: '081234567890',
      },
      dropoff: {
        label: 'Tujuan',
        address: 'Warung Kopi Biru, Batang',
        district: 'Batang',
        lat: -5.5891,
        lng: 119.7512,
        contactName: 'Pak Daeng',
        contactPhone: '081244433322',
      },
      category: 'Elektronik',
      weightKg: 1,
      notes: 'Barang elektronik, bungkus bubble wrap.',
      courier: true,
      acceptedAt: '2026-10-28T06:35:00Z',
    },
  ];

  for (const order of orders) {
    const distance = order.distanceKm;
    const f = fare(distance);
    const created = order.createdAt;
    const updated = order.updatedAt;
    const courierFields = order.courier ? courierId : null;
    const courierName = order.courier ? 'Andi Pratama' : null;
    const courierPhone = order.courier ? '081298765432' : null;

    await putDoc('orders', order.id, {
      code: str(order.code),
      customerId: str(customerId),
      customerName: str('Budi Santoso'),
      customerPhone: str('081234567890'),
      courierId: courierFields ? str(courierFields) : nil(),
      courierName: courierName ? str(courierName) : nil(),
      courierPhone: courierPhone ? str(courierPhone) : nil(),
      pickup: map(address(order.pickup)),
      dropoff: map(address(order.dropoff)),
      pickupAddress: str(
        `${order.pickup.address}, ${order.pickup.district}`,
      ),
      destinationAddress: str(
        `${order.dropoff.address}, ${order.dropoff.district}`,
      ),
      pickupDistrict: str(order.pickup.district),
      dropoffDistrict: str(order.dropoff.district),
      pickupLat: dbl(order.pickup.lat),
      pickupLng: dbl(order.pickup.lng),
      dropoffLat: dbl(order.dropoff.lat),
      dropoffLng: dbl(order.dropoff.lng),
      recipientName: str(order.dropoff.contactName),
      recipientPhone: str(order.dropoff.contactPhone),
      note: str(order.notes),
      itemCategory: str(order.category),
      itemNotes: str(order.notes),
      weightKg: dbl(order.weightKg),
      distanceKm: dbl(distance),
      price: int(f.total),
      fare: map({
        distanceKm: dbl(distance),
        billableDistanceKm: dbl(f.billable),
        baseFare: int(f.baseFare),
        perKmFare: int(f.perKmFare),
        distanceCharge: int(f.distanceCharge),
        roundingAdjustment: int(f.roundingAdjustment),
        total: int(f.total),
        minimumApplied: bool(f.minimumApplied),
      }),
      status: str(order.status),
      paymentMethod: str(order.paymentMethod),
      paymentStatus: str(order.paymentStatus),
      paymentProvider: str(order.paymentMethod === 'midtrans' ? 'midtrans' : 'cash'),
      createdAt: ts(created),
      updatedAt: ts(updated),
      acceptedAt: order.acceptedAt ? ts(order.acceptedAt) : nil(),
      deliveredAt: order.deliveredAt ? ts(order.deliveredAt) : nil(),
      paidAt: order.deliveredAt ? ts(order.deliveredAt) : nil(),
      cancelledAt: nil(),
      cancelledReason: nil(),
    });
  }

  await putDoc('wallets', courierId, {
    uid: str(courierId),
    balance: int(45000),
    pendingBalance: int(0),
    totalEarnings: int(50000),
    totalWithdrawn: int(0),
    updatedAt: ts('2026-10-26T10:05:00Z'),
  });

  const transactions = [
    {
      id: 'tx-demo-1',
      orderId: 'demo-order-1',
      amount: 16650,
      description: 'Pendapatan pesanan JK-DEMO-001',
      createdAt: '2026-10-26T10:05:00Z',
    },
    {
      id: 'tx-demo-2',
      orderId: 'demo-order-0',
      amount: 33350,
      description: 'Pendapatan pesanan JK-DEMO-000',
      createdAt: '2026-10-24T16:40:00Z',
    },
  ];

  for (const tx of transactions) {
    await putDoc('wallet_transactions', tx.id, {
      uid: str(courierId),
      orderId: str(tx.orderId),
      type: str('earning'),
      amount: int(tx.amount),
      status: str('completed'),
      description: str(tx.description),
      createdAt: ts(tx.createdAt),
    });
  }

  console.log('\nSeed selesai. Login demo:');
  console.log('  customer@demo.test / password123');
  console.log('  courier@demo.test  / password123');
  console.log('  admin@demo.test    / password123');
  console.log(`\nCustomer UID: ${customerId}`);
  console.log(`Courier UID : ${courierId}`);
  console.log(`Admin UID   : ${adminId}`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
