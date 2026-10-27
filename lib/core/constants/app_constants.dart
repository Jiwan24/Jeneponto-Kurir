/// Konstanta umum aplikasi (tarif, label, dsb).
class AppConstants {
  AppConstants._();

  static const String appName = 'Jeneponto Kurir';
  static const String tagline = 'Kirim apa saja, di mana saja di Jeneponto';
  static const String currencyCode = 'IDR';

  /// Tarif dasar (Rp) yang dibebankan sekali per pengiriman.
  static const int baseFare = 8000;

  /// Tarif per kilometer (Rp).
  static const int perKmFare = 2500;

  /// Jarak minimum yang tetap dibebankan meski pengiriman dekat.
  static const double minimumDistanceKm = 1.0;

  /// Pembulatan tarif ke atas dalam kelipatan Rp500.
  static const int priceRoundingStep = 500;

  /// Batas jarak pengiriman yang diterima aplikasi (km).
  static const double maximumDeliveryDistanceKm = 30;

  /// Batas berat paket (kg) untuk fase MVP.
  static const double maximumItemWeightKg = 50;

  /// Faktor koreksi jarak garis lurus → perkiraan jarak jalan.
  ///
  /// Titik peta memberi jarak haversine; jalan di Jeneponto tidak lurus.
  /// Angka ini sengaja konservatif dan dapat diganti bila integrasi rute
  /// (Directions API) sudah tersedia.
  static const double roadDistanceFactor = 1.3;

  /// Komisi platform default (persen) bila `config/finance` belum diisi.
  static const int defaultCommissionPct = 10;

  /// Minimal saldo dompet kurir untuk penarikan (Rp).
  static const int minimumPayout = 50000;

  /// Region Cloud Functions (sesuaikan dengan lokasi Firestore).
  static const String functionsRegion = 'asia-southeast2';

  /// Nama callable function pembuat transaksi Midtrans.
  static const String midtransFunction = 'createMidtransPayment';

  /// Halaman tujuan setelah pembayaran di browser Midtrans.
  ///
  /// Tidak dipakai untuk deep link; aplikasi memantau status di Firestore.
  static const String paymentFinishUrl = String.fromEnvironment(
    'PAYMENT_FINISH_URL',
    defaultValue: 'https://jeneponto-kurir.web.app/payment/finish',
  );

  /// Lokasi bawaan format mata uang dan tanggal.
  static const String localeId = 'id_ID';

  /// Nomor layanan pelanggan (ganti sebelum rilis).
  static const String supportPhone = '+62 812-0000-0000';

  static const String aboutText =
      'Jeneponto Kurir membantu warga Jeneponto mengirim paket, dokumen, '
      'dan barang antar kecamatan dengan kurir lokal yang terverifikasi.';
}
