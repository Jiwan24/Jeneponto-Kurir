import '../../../common/constants/app_constants.dart';

/// Validator input formulir pemesanan Person 2.
class Validators {
  Validators._();

  static String? required(String? value, {String field = 'Kolom ini'}) {
    if (value == null || value.trim().isEmpty) {
      return '$field wajib diisi.';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Nomor HP wajib diisi.';
    final String digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 9 || digits.length > 15) {
      return 'Nomor HP tidak valid.';
    }
    return null;
  }

  /// Nama orang (pengirim/penerima). Minimal 2 karakter, tanpa angka.
  static String? personName(String? value, {String field = 'Nama'}) {
    if (value == null || value.trim().isEmpty) return '$field wajib diisi.';
    final String name = value.trim();
    if (name.length < 2) return '$field minimal 2 karakter.';
    if (name.length > 60) return '$field maksimal 60 karakter.';
    if (!RegExp(r"^[A-Za-z\u00C0-\u024F .'\-]+$").hasMatch(name)) {
      return '$field hanya boleh berisi huruf, spasi, titik, atau tanda hubung.';
    }
    return null;
  }

  /// Alamat teks (nama jalan, patokan, nomor rumah).
  static String? addressDetail(String? value, {String field = 'Alamat'}) {
    if (value == null || value.trim().isEmpty) return '$field wajib diisi.';
    final String address = value.trim();
    if (address.length < 8) return '$field terlalu singkat (min. 8 karakter).';
    if (address.length > 200) return '$field maksimal 200 karakter.';
    return null;
  }

  /// Jarak tempuh dalam km: 0,5–30 km (menerima koma desimal).
  static String? distanceKm(String? value) {
    if (value == null || value.trim().isEmpty) return 'Jarak wajib diisi.';
    final double? parsed = double.tryParse(value.replaceAll(',', '.').trim());
    if (parsed == null || parsed <= 0) {
      return 'Jarak harus angka lebih dari 0.';
    }
    if (parsed < 0.5) return 'Jarak minimal 0,5 km.';
    if (parsed > AppConstants.maximumDeliveryDistanceKm) {
      return 'Jarak maksimal ${AppConstants.maximumDeliveryDistanceKm.toInt()} km.';
    }
    return null;
  }

  /// Berat paket opsional; bila diisi harus 0,1–50 kg.
  static String? weightKg(String? value, {double? defaultValue = 1}) {
    if (value == null || value.trim().isEmpty) {
      return defaultValue == null ? 'Berat paket wajib diisi.' : null;
    }
    final double? parsed = double.tryParse(value.replaceAll(',', '.').trim());
    if (parsed == null || parsed <= 0) {
      return 'Berat harus angka lebih dari 0.';
    }
    if (parsed < 0.1) return 'Berat minimal 0,1 kg.';
    if (parsed > AppConstants.maximumItemWeightKg) {
      return 'Berat maksimal ${AppConstants.maximumItemWeightKg.toInt()} kg.';
    }
    return null;
  }

  static String? itemNotes(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (value.trim().length > 200) return 'Catatan maksimal 200 karakter.';
    return null;
  }

  /// Validasi titik peta sudah dipilih.
  static String? pointSelected(bool hasPoint, {String field = 'Titik lokasi'}) {
    if (!hasPoint) return '$field wajib dipilih di peta.';
    return null;
  }

  /// Validasi titik berada di area layanan.
  static String? serviceArea(bool inside) {
    if (!inside) {
      return 'Lokasi berada di luar area layanan Kabupaten Jeneponto.';
    }
    return null;
  }

  /// Kecamatan wajib dipilih dari daftar.
  static String? district(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Kecamatan wajib dipilih.';
    }
    return null;
  }
}
