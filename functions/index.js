/**
 * Cloud Functions Jeneponto Kurir.
 *
 * Fungsi:
 * 1. createMidtransPayment  - callable, membuat transaksi Snap.
 * 2. midtransWebhook         - HTTP, menerima notifikasi pembayaran.
 * 3. onOrderDelivered        - trigger Firestore, mencatat pembayaran COD
 *                              dan mengkredit dompet kurir.
 *
 * Deploy:
 *   firebase deploy --only functions
 *
 * Secret yang dibutuhkan:
 *   firebase functions:secrets:set MIDTRANS_SERVER_KEY
 *
 * Variabel non-secret (functions/.env.<projectId>):
 *   MIDTRANS_IS_PRODUCTION=false
 *   PAYMENT_FINISH_URL=https://jeneponto-kurir.web.app/payment/finish
 */

const crypto = require('node:crypto');
const { setGlobalOptions } = require('firebase-functions/v2');
const { onCall, onRequest, HttpsError } = require('firebase-functions/v2/https');
const { onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { defineSecret, defineString } = require('firebase-functions/params');
const admin = require('firebase-admin');

admin.initializeApp();

const db = admin.firestore();
const REGION = 'asia-southeast2';
const DEFAULT_COMMISSION_PCT = 10;

// Samakan dengan lib/core/constants/app_constants.dart. Harga final dihitung
// ulang di server agar nominal Midtrans/dompet tidak bisa dipalsukan client.
const BASE_FARE = 8000;
const PER_KM_FARE = 2500;
const MINIMUM_DISTANCE_KM = 1;
const ROUNDING_STEP = 500;
const ROAD_DISTANCE_FACTOR = 1.3;
const MAXIMUM_DELIVERY_DISTANCE_KM = 30;
const EARTH_RADIUS_KM = 6371.0088;

// Bounding box Kabupaten Jeneponto (samakan dengan data OSM di aplikasi).
const JENEPONTO_MIN_LAT = -5.702882;
const JENEPONTO_MAX_LAT = -5.386112;
const JENEPONTO_MIN_LNG = 119.484864;
const JENEPONTO_MAX_LNG = 119.938099;

const midtransServerKey = defineSecret('MIDTRANS_SERVER_KEY');
const midtransIsProduction = defineString('MIDTRANS_IS_PRODUCTION', {
  default: 'false',
});
const paymentFinishUrl = defineString('PAYMENT_FINISH_URL', {
  default: 'https://jeneponto-kurir.web.app/payment/finish',
});

setGlobalOptions({ region: REGION, maxInstances: 20 });

const SNAP_SANDBOX = 'https://app.sandbox.midtrans.com/snap/v1/transactions';
const SNAP_PRODUCTION = 'https://app.midtrans.com/snap/v1/transactions';

function snapUrl() {
  return midtransIsProduction.value() === 'true'
    ? SNAP_PRODUCTION
    : SNAP_SANDBOX;
}

function orderNumber(orderId) {
  // Midtrans membatasi order_id maksimal 50 karakter.
  const compact = String(orderId).replace(/-/g, '').slice(0, 24);
  return `${compact}-${Date.now()}`;
}

function amountOf(order) {
  const amount = Math.round(Number(order.price) || 0);
  return Number.isFinite(amount) && amount > 0 ? amount : 0;
}

function coordinateFrom(address) {
  if (!address || typeof address !== 'object') return null;
  const lat = Number(address.lat);
  const lng = Number(address.lng);
  if (!Number.isFinite(lat) || !Number.isFinite(lng)) return null;
  if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return null;
  if (lat === 0 && lng === 0) return null;
  return { lat, lng };
}

function insideJeneponto(point) {
  return (
    point.lat >= JENEPONTO_MIN_LAT &&
    point.lat <= JENEPONTO_MAX_LAT &&
    point.lng >= JENEPONTO_MIN_LNG &&
    point.lng <= JENEPONTO_MAX_LNG
  );
}

function haversineKm(from, to) {
  const toRadians = (degrees) => (degrees * Math.PI) / 180;
  const dLat = toRadians(to.lat - from.lat);
  const dLng = toRadians(to.lng - from.lng);
  const lat1 = toRadians(from.lat);
  const lat2 = toRadians(to.lat);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.sin(dLng / 2) *
      Math.sin(dLng / 2) *
      Math.cos(lat1) *
      Math.cos(lat2);
  return EARTH_RADIUS_KM * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

/**
 * Hitung tarif dari titik peta. Mengembalikan `{error}` bila titik ada tetapi
 * tidak valid / di luar batas; `null` bila order lama tidak punya jarak.
 */
function quoteOrderFare(order) {
  const pickup = coordinateFrom(order.pickup);
  const dropoff = coordinateFrom(order.dropoff);

  let rawDistanceKm;
  if (pickup || dropoff) {
    // Pesanan baru wajib punya kedua titik. Jangan fallback ke jarak dari
    // client bila salah satu titik hilang.
    if (!pickup || !dropoff) return { error: 'invalid-coordinates' };
    if (!insideJeneponto(pickup) || !insideJeneponto(dropoff)) {
      return { error: 'outside-service-area' };
    }
    rawDistanceKm = haversineKm(pickup, dropoff) * ROAD_DISTANCE_FACTOR;
  } else {
    // Order lama tidak punya titik peta; pakai jarak yang tersimpan.
    const stored = Number(order.distanceKm);
    if (!Number.isFinite(stored) || stored <= 0) return null;
    rawDistanceKm = stored;
  }

  if (!Number.isFinite(rawDistanceKm) || rawDistanceKm <= 0) {
    return { error: 'invalid-distance' };
  }
  if (rawDistanceKm > MAXIMUM_DELIVERY_DISTANCE_KM) {
    return { error: 'distance-too-far' };
  }

  // Form menyimpan jarak minimal 0,5 km; tarif minimum tetap 1 km.
  const distanceKm = Math.max(0.5, rawDistanceKm);
  const billableDistanceKm = Math.max(MINIMUM_DISTANCE_KM, distanceKm);
  const distanceCharge = Math.round(billableDistanceKm * PER_KM_FARE);
  const rawTotal = BASE_FARE + distanceCharge;
  const total = Math.ceil(rawTotal / ROUNDING_STEP) * ROUNDING_STEP;

  return {
    distanceKm,
    billableDistanceKm,
    baseFare: BASE_FARE,
    perKmFare: PER_KM_FARE,
    distanceCharge,
    roundingAdjustment: total - rawTotal,
    total,
    minimumApplied: distanceKm < MINIMUM_DISTANCE_KM,
  };
}

function fareError(fare) {
  if (!fare || !fare.error) return null;
  if (fare.error === 'distance-too-far') {
    return `Jarak pengiriman melebihi ${MAXIMUM_DELIVERY_DISTANCE_KM} km.`;
  }
  if (fare.error === 'outside-service-area') {
    return 'Titik pengiriman berada di luar area layanan Jeneponto.';
  }
  return 'Titik pengiriman tidak valid. Pilih ulang titik di peta.';
}

function mapMidtransStatus(transactionStatus, fraudStatus) {
  switch (transactionStatus) {
    case 'capture':
      return fraudStatus === 'challenge' ? 'pending' : 'paid';
    case 'settlement':
      return 'paid';
    case 'pending':
      return 'pending';
    case 'deny':
    case 'cancel':
    case 'failure':
      return 'failed';
    case 'expire':
      return 'expired';
    case 'refund':
    case 'partial_refund':
      return 'refunded';
    default:
      return 'pending';
  }
}

async function commissionPct() {
  try {
    const snap = await db.doc('config/finance').get();
    const raw = Number(snap.data()?.commissionPct);
    if (Number.isFinite(raw) && raw >= 0 && raw <= 100) return raw;
  } catch (error) {
    console.warn('Gagal membaca config/finance:', error.message);
  }
  return DEFAULT_COMMISSION_PCT;
}

exports.createMidtransPayment = onCall(
  {
    region: REGION,
    secrets: [midtransServerKey],
    cors: true,
    timeoutSeconds: 60,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError(
        'unauthenticated',
        'Silakan masuk untuk melanjutkan pembayaran.',
      );
    }

    const uid = request.auth.uid;
    const orderId = String(request.data?.orderId || '').trim();
    if (!orderId) {
      throw new HttpsError('invalid-argument', 'orderId wajib diisi.');
    }

    const orderRef = db.collection('orders').doc(orderId);
    const orderSnap = await orderRef.get();
    if (!orderSnap.exists) {
      throw new HttpsError('not-found', 'Pesanan tidak ditemukan.');
    }

    const order = orderSnap.data();
    if (order.customerId !== uid) {
      throw new HttpsError(
        'permission-denied',
        'Pesanan ini bukan milik akun kamu.',
      );
    }
    if (order.paymentMethod !== 'midtrans') {
      throw new HttpsError(
        'failed-precondition',
        'Pesanan ini tidak menggunakan pembayaran online.',
      );
    }
    if (order.paymentStatus === 'paid') {
      throw new HttpsError(
        'failed-precondition',
        'Pesanan ini sudah dibayar.',
      );
    }
    if (!['awaitingPayment', 'pending'].includes(order.status)) {
      throw new HttpsError(
        'failed-precondition',
        'Pesanan tidak dapat dibayar pada status saat ini.',
      );
    }

    const fare = quoteOrderFare(order);
    const invalidFare = fareError(fare);
    if (invalidFare) {
      throw new HttpsError('failed-precondition', invalidFare);
    }
    if (!fare) {
      throw new HttpsError(
        'failed-precondition',
        'Titik peta pesanan belum lengkap. Buat pesanan ulang dari peta.',
      );
    }

    const amount = fare.total;
    if (amount <= 0) {
      throw new HttpsError(
        'failed-precondition',
        'Total pembayaran pesanan tidak valid.',
      );
    }

    const paymentRef = db.collection('payments').doc(orderId);
    const existingSnap = await paymentRef.get();
    if (existingSnap.exists && existingSnap.data().status === 'paid') {
      throw new HttpsError(
        'failed-precondition',
        'Pembayaran pesanan ini sudah tercatat lunas.',
      );
    }

    const serverKey = midtransServerKey.value();
    if (!serverKey) {
      throw new HttpsError(
        'failed-precondition',
        'MIDTRANS_SERVER_KEY belum dikonfigurasi.',
      );
    }

    const midtransOrderId = orderNumber(orderId);
    const payload = {
      transaction_details: {
        order_id: midtransOrderId,
        gross_amount: amount,
      },
      item_details: [
        {
          id: 'delivery',
          price: amount,
          quantity: 1,
          name: `Pengiriman ${order.code || orderId}`.slice(0, 50),
        },
      ],
      customer_details: {
        first_name: order.customerName || 'Pelanggan',
        phone: order.customerPhone || '',
      },
      callbacks: { finish: paymentFinishUrl.value() },
      custom_field1: orderId,
      custom_field2: uid,
    };

    let response;
    try {
      response = await fetch(snapUrl(), {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Accept: 'application/json',
          Authorization: `Basic ${Buffer.from(`${serverKey}:`).toString(
            'base64',
          )}`,
        },
        body: JSON.stringify(payload),
      });
    } catch (error) {
      console.error('Gagal menghubungi Midtrans:', error);
      throw new HttpsError(
        'unavailable',
        'Layanan pembayaran sedang tidak dapat dihubungi.',
      );
    }

    const data = await response.json().catch(() => ({}));
    if (!response.ok || !data.token) {
      console.error('Respons Midtrans tidak valid:', response.status, data);
      throw new HttpsError(
        'internal',
        'Gagal membuat transaksi pembayaran. Coba lagi.',
      );
    }

    const now = admin.firestore.FieldValue.serverTimestamp();
    const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000);
    const redirectBase =
      midtransIsProduction.value() === 'true'
        ? 'https://app.midtrans.com/snap/v2/vtweb'
        : 'https://app.sandbox.midtrans.com/snap/v2/vtweb';
    const redirectUrl = data.redirect_url || `${redirectBase}/${data.token}`;

    const orderUpdate = {
      paymentId: orderId,
      paymentMethod: 'midtrans',
      paymentStatus: 'pending',
      updatedAt: now,
    };
    if (fare) {
      // Perbaiki harga lama / harga yang tidak konsisten dengan titik peta.
      orderUpdate.price = amount;
      orderUpdate.distanceKm = fare.distanceKm;
      orderUpdate.fare = fare;
    }

    await Promise.all([
      paymentRef.set(
        {
          orderId,
          orderCode: order.code || '',
          customerId: uid,
          courierId: order.courierId || null,
          amount,
          provider: 'midtrans',
          method: 'midtrans',
          status: 'pending',
          midtransOrderId,
          snapToken: data.token,
          redirectUrl,
          paidAt: null,
          transactionId: null,
          channel: null,
          failureReason: null,
          createdAt: existingSnap.exists
            ? existingSnap.data().createdAt || now
            : now,
          updatedAt: now,
          expiresAt: admin.firestore.Timestamp.fromDate(expiresAt),
        },
        { merge: true },
      ),
      orderRef.update(orderUpdate),
    ]);

    return {
      token: data.token,
      snapToken: data.token,
      redirectUrl,
      midtransOrderId,
      amount,
      expiresAt: expiresAt.toISOString(),
    };
  },
);

exports.midtransWebhook = onRequest(
  {
    region: REGION,
    secrets: [midtransServerKey],
    timeoutSeconds: 30,
  },
  async (request, response) => {
    if (request.method !== 'POST') {
      response.status(405).send('Method Not Allowed');
      return;
    }

    const body = request.body || {};
    const {
      order_id: midtransOrderId,
      status_code: statusCode,
      gross_amount: grossAmount,
      signature_key: signatureKey,
      transaction_status: transactionStatus,
      fraud_status: fraudStatus,
      payment_type: paymentType,
      transaction_id: transactionId,
      status_message: statusMessage,
    } = body;

    const serverKey = midtransServerKey.value();
    if (!serverKey) {
      console.error('MIDTRANS_SERVER_KEY belum dikonfigurasi.');
      response.status(500).send('Payment provider not configured');
      return;
    }

    const expectedSignature = crypto
      .createHash('sha512')
      .update(
        `${midtransOrderId || ''}${statusCode || ''}${grossAmount || ''}${
          serverKey || ''
        }`,
      )
      .digest('hex');

    if (!signatureKey || expectedSignature !== signatureKey) {
      console.warn('Signature Midtrans tidak valid untuk', midtransOrderId);
      response.status(403).send('Invalid signature');
      return;
    }

    if (!midtransOrderId) {
      response.status(400).send('Missing order_id');
      return;
    }

    let paymentSnap = await db
      .collection('payments')
      .where('midtransOrderId', '==', midtransOrderId)
      .limit(1)
      .get();

    let paymentRef = paymentSnap.empty ? null : paymentSnap.docs[0].ref;
    let orderId = paymentSnap.empty ? null : paymentSnap.docs[0].data().orderId;

    // Fallback bila custom_field1 tersedia di notifikasi.
    if (!paymentRef && body.custom_field1) {
      orderId = String(body.custom_field1);
      paymentRef = db.collection('payments').doc(orderId);
    }

    if (!paymentRef || !orderId) {
      console.error('Pembayaran tidak ditemukan untuk', midtransOrderId);
      response.status(404).send('Payment not found');
      return;
    }

    const paymentDoc = paymentSnap.empty
      ? await paymentRef.get()
      : paymentSnap.docs[0];
    if (!paymentDoc.exists) {
      console.error('Dokumen pembayaran tidak ditemukan untuk', orderId);
      response.status(404).send('Payment not found');
      return;
    }

    const payment = paymentDoc.data() || {};
    if (String(payment.orderId || '') !== String(orderId)) {
      response.status(400).send('Payment/order mismatch');
      return;
    }
    if (
      body.custom_field1 &&
      String(body.custom_field1) !== String(orderId)
    ) {
      response.status(400).send('Payment/order mismatch');
      return;
    }

    const expectedAmount = Math.round(Number(payment.amount) || 0);
    if (
      expectedAmount > 0 &&
      Math.round(Number(grossAmount)) !== expectedAmount
    ) {
      console.warn(
        'Nominal webhook tidak cocok untuk',
        orderId,
        grossAmount,
        expectedAmount,
      );
      response.status(400).send('Amount mismatch');
      return;
    }

    const status = mapMidtransStatus(transactionStatus, fraudStatus);

    // Jangan turunkan status pembayaran yang sudah lunas karena notifikasi
    // lama/duplikat. Refund tetap boleh dicatat.
    if (
      payment.status === 'paid' &&
      status !== 'paid' &&
      status !== 'refunded'
    ) {
      response.status(200).json({ status: 'ignored' });
      return;
    }
    // Refund adalah status terminal; notifikasi lama tidak boleh
    // mengembalikannya menjadi paid/pending.
    if (payment.status === 'refunded' && status !== 'refunded') {
      response.status(200).json({ status: 'ignored' });
      return;
    }

    const now = admin.firestore.FieldValue.serverTimestamp();
    const orderRef = db.collection('orders').doc(orderId);

    const paymentUpdate = {
      status,
      channel: paymentType || null,
      transactionId: transactionId || null,
      failureReason:
        status === 'failed' || status === 'expired'
          ? statusMessage || null
          : null,
      updatedAt: now,
    };

    if (status === 'paid') {
      paymentUpdate.paidAt = now;
    }

    const batch = db.batch();
    batch.set(paymentRef, paymentUpdate, { merge: true });

    const orderSnap = await orderRef.get();
    if (orderSnap.exists) {
      const order = orderSnap.data();
      const orderUpdate = {
        paymentStatus: status,
        updatedAt: now,
      };

      // Hanya order gateway yang menunggu pembayaran yang dipindahkan ke
      // job board kurir. Order COD tidak melewati webhook ini.
      if (status === 'paid') {
        orderUpdate.paidAt = now;
        orderUpdate.paymentId = orderId;
        if (order.status === 'awaitingPayment') {
          orderUpdate.status = 'pending';
        }
      }

      if (status === 'refunded') {
        orderUpdate.paymentStatus = 'refunded';
      }

      batch.update(orderRef, orderUpdate);
    }

    await batch.commit();
    response.status(200).json({ status: 'ok' });
  },
);

exports.onOrderDelivered = onDocumentUpdated(
  {
    document: 'orders/{orderId}',
    region: REGION,
    timeoutSeconds: 60,
  },
  async (event) => {
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();
    if (!before || !after) return;

    // Hanya proses transisi pertama ke delivered.
    if (after.status !== 'delivered' || before.status === 'delivered') return;

    const orderId = event.params.orderId;
    const courierId = after.courierId;
    if (!courierId) return;

    const fare = quoteOrderFare(after);
    if (fare && fare.error) {
      console.warn('Order delivered dengan tarif tidak valid:', orderId, fare.error);
      return;
    }

    const fallbackGross = fare ? fare.total : amountOf(after);
    if (fallbackGross <= 0) return;

    const percentage = await commissionPct();

    const orderRef = db.collection('orders').doc(orderId);
    const walletRef = db.collection('wallets').doc(courierId);
    const earningRef = db
      .collection('wallet_transactions')
      .doc(`earning_${orderId}`);
    const paymentRef = db.collection('payments').doc(orderId);
    // Order lama tidak punya paymentMethod; anggap COD.
    const isCod = after.paymentMethod !== 'midtrans';
    const now = admin.firestore.FieldValue.serverTimestamp();

    await db.runTransaction(async (transaction) => {
      const earningSnap = await transaction.get(earningRef);
      if (earningSnap.exists) return;

      const walletSnap = await transaction.get(walletRef);
      const wallet = walletSnap.exists ? walletSnap.data() : {};

      // Pembayaran gateway memakai nominal yang benar-benar dibayar.
      const paymentSnap = await transaction.get(paymentRef);
      const paymentPaid =
        paymentSnap.exists && paymentSnap.data().status === 'paid';
      const paidAmount = paymentPaid
        ? Math.round(Number(paymentSnap.data().amount) || 0)
        : 0;

      // Order gateway hanya boleh dikreditkan setelah pembayarannya benar-
      // benar tercatat lunas. COD tetap memakai tarif server.
      if (!isCod && (!paymentPaid || paidAmount <= 0)) {
        console.warn(
          'Order gateway delivered tanpa pembayaran lunas:',
          orderId,
        );
        return;
      }

      const gross = isCod ? fallbackGross : paidAmount;
      if (gross <= 0) return;

      const commission = Math.round((gross * percentage) / 100);
      const net = Math.max(0, gross - commission);

      if (net > 0) {
        transaction.set(earningRef, {
          uid: courierId,
          orderId,
          type: 'earning',
          amount: net,
          status: 'available',
          description: `Pendapatan order ${after.code || orderId}`,
          createdAt: now,
        });

        transaction.set(
          walletRef,
          {
            uid: courierId,
            balance: admin.firestore.FieldValue.increment(net),
            totalEarnings: admin.firestore.FieldValue.increment(net),
            totalWithdrawn: wallet.totalWithdrawn || 0,
            updatedAt: now,
          },
          { merge: true },
        );
      }

      const orderUpdate = {
        walletCredited: true,
        walletCommission: commission,
        walletEarning: net,
        updatedAt: now,
      };

      if (isCod && fare && !paymentPaid) {
        // Simpan tarif server-authoritative saat COD diselesaikan.
        orderUpdate.price = fare.total;
        orderUpdate.distanceKm = fare.distanceKm;
        orderUpdate.fare = fare;
      }

      // COD lunas saat paket diterima, sekaligus catat payment agar riwayat
      // pembayaran pelanggan konsisten dengan order gateway.
      if (isCod && after.paymentStatus !== 'paid') {
        orderUpdate.paymentStatus = 'paid';
        orderUpdate.paidAt = now;
        transaction.set(
          paymentRef,
          {
            orderId,
            orderCode: after.code || '',
            customerId: after.customerId || '',
            courierId,
            amount: gross,
            provider: 'cash',
            method: 'cod',
            status: 'paid',
            createdAt: now,
            updatedAt: now,
            paidAt: now,
          },
          { merge: true },
        );
      }

      transaction.update(orderRef, orderUpdate);
    });
  },
);
