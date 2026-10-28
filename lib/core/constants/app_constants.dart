/// Konstanta umum aplikasi (tarif, label, dsb).
class AppConstants {
  AppConstants._();

  static const String appName = 'Jeneponto Kurir';
  static const String tagline = 'Kirim apa saja, di mana saja di Jeneponto';

  /// Tarif dasar (Rp) yang dibebankan sekali per pengiriman.
  static const int baseFare = 8000;

  /// Tarif per kilometer (Rp).
  static const int perKmFare = 2500;

  /// Jarak minimum yang tetap dibebankan meski pengiriman dekat.
  static const double minimumDistanceKm = 1.0;

  /// Pembulatan tarif ke atas dalam kelipatan Rp500.
  static const int priceRoundingStep = 500;

  /// Lokasi bawaan format mata uang dan tanggal.
  static const String localeId = 'id_ID';

  /// Nomor layanan pelanggan (ganti sebelum rilis).
  static const String supportPhone = '+62 812-0000-0000';

  static const String aboutText =
      'Jeneponto Kurir membantu warga Jeneponto mengirim paket, dokumen, '
      'dan barang antar kecamatan dengan kurir lokal yang terverifikasi.';
}
