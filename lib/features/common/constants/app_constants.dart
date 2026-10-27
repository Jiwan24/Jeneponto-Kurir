/// Konstanta khusus modul Person 2 (pemesanan, pembayaran, dompet).
class AppConstants {
  AppConstants._();

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

  /// Faktor koreksi jarak garis lurus menjadi perkiraan jarak jalan.
  static const double roadDistanceFactor = 1.3;

  /// Minimal saldo dompet kurir untuk penarikan (Rp).
  static const int minimumPayout = 50000;

  /// Region Cloud Functions (sesuaikan dengan lokasi Firestore).
  static const String functionsRegion = 'asia-southeast2';

  /// Nama callable function pembuat transaksi Midtrans.
  static const String midtransFunction = 'createMidtransPayment';

  /// Lokasi bawaan format mata uang dan tanggal.
  static const String localeId = 'id_ID';

  /// Nomor layanan pelanggan (ganti sebelum rilis).
  static const String supportPhone = '+62 812-0000-0000';
}
