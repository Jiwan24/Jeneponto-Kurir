import '../constants/app_constants.dart';

/// Konfigurasi tarif yang bisa di-snapshot ke dokumen pesanan.
///
/// Nilai default mengikuti [AppConstants] agar form dan riwayat konsisten.
class FareConfig {
  const FareConfig({
    this.baseFare = AppConstants.baseFare,
    this.perKmFare = AppConstants.perKmFare,
    this.minimumDistanceKm = AppConstants.minimumDistanceKm,
    this.roundingStep = AppConstants.priceRoundingStep,
  });

  final int baseFare;
  final int perKmFare;
  final double minimumDistanceKm;
  final int roundingStep;

  FareConfig copyWith({
    int? baseFare,
    int? perKmFare,
    double? minimumDistanceKm,
    int? roundingStep,
  }) {
    return FareConfig(
      baseFare: baseFare ?? this.baseFare,
      perKmFare: perKmFare ?? this.perKmFare,
      minimumDistanceKm: minimumDistanceKm ?? this.minimumDistanceKm,
      roundingStep: roundingStep ?? this.roundingStep,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'baseFare': baseFare,
        'perKmFare': perKmFare,
        'minimumDistanceKm': minimumDistanceKm,
        'roundingStep': roundingStep,
      };

  factory FareConfig.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const FareConfig();
    return FareConfig(
      baseFare: (map['baseFare'] as num?)?.toInt() ?? AppConstants.baseFare,
      perKmFare: (map['perKmFare'] as num?)?.toInt() ?? AppConstants.perKmFare,
      minimumDistanceKm: (map['minimumDistanceKm'] as num?)?.toDouble() ??
          AppConstants.minimumDistanceKm,
      roundingStep: (map['roundingStep'] as num?)?.toInt() ??
          AppConstants.priceRoundingStep,
    );
  }
}

/// Rincian tarif yang ditampilkan ke pelanggan dan disimpan ke pesanan.
class FareBreakdown {
  const FareBreakdown({
    required this.distanceKm,
    required this.billableDistanceKm,
    required this.baseFare,
    required this.perKmFare,
    required this.distanceCharge,
    required this.roundingAdjustment,
    required this.total,
    required this.minimumApplied,
  });

  /// Jarak yang dipakai untuk perhitungan (sudah dikali faktor jalan).
  final double distanceKm;

  /// Jarak yang benar-benar dibebankan (minimal [minimumDistanceKm]).
  final double billableDistanceKm;

  final int baseFare;
  final int perKmFare;
  final int distanceCharge;

  /// Selisih pembulatan ke atas, agar base + distance + adjustment = total.
  final int roundingAdjustment;
  final int total;
  final bool minimumApplied;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'distanceKm': distanceKm,
        'billableDistanceKm': billableDistanceKm,
        'baseFare': baseFare,
        'perKmFare': perKmFare,
        'distanceCharge': distanceCharge,
        'roundingAdjustment': roundingAdjustment,
        'total': total,
        'minimumApplied': minimumApplied,
      };

  factory FareBreakdown.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const FareBreakdown(
        distanceKm: 0,
        billableDistanceKm: 0,
        baseFare: 0,
        perKmFare: 0,
        distanceCharge: 0,
        roundingAdjustment: 0,
        total: 0,
        minimumApplied: true,
      );
    }
    return FareBreakdown(
      distanceKm: (map['distanceKm'] as num?)?.toDouble() ?? 0,
      billableDistanceKm: (map['billableDistanceKm'] as num?)?.toDouble() ?? 0,
      baseFare: (map['baseFare'] as num?)?.toInt() ?? 0,
      perKmFare: (map['perKmFare'] as num?)?.toInt() ?? 0,
      distanceCharge: (map['distanceCharge'] as num?)?.toInt() ?? 0,
      roundingAdjustment: (map['roundingAdjustment'] as num?)?.toInt() ?? 0,
      total: (map['total'] as num?)?.toInt() ?? 0,
      minimumApplied: map['minimumApplied'] as bool? ?? true,
    );
  }
}

/// Perhitungan tarif pengiriman.
///
/// Rumus: `baseFare + (jarak yang dibebankan × perKmFare)`, lalu dibulatkan
/// ke atas per [FareConfig.roundingStep]. Jarak minimum tetap dibebankan
/// meski pengiriman sangat dekat.
///
/// Catatan keamanan: ini **estimasi client**. Sumber kebenaran harga final
/// adalah Cloud Function saat pesanan dibuat/dibayar (lihat docs).
class PriceCalculator {
  PriceCalculator._();

  /// Rincian tarif lengkap (dipakai form & halaman detail).
  static FareBreakdown quote({
    required double distanceKm,
    FareConfig config = const FareConfig(),
  }) {
    final double safeDistance =
        distanceKm.isFinite && distanceKm > 0 ? distanceKm : 0;
    final bool minimumApplied = safeDistance < config.minimumDistanceKm;
    final double billable =
        minimumApplied ? config.minimumDistanceKm : safeDistance;

    final int distanceCharge = (billable * config.perKmFare).round();
    final int rawTotal = config.baseFare + distanceCharge;
    final int step = config.roundingStep > 0 ? config.roundingStep : 1;
    final int total = (rawTotal / step).ceil() * step;

    return FareBreakdown(
      distanceKm: safeDistance,
      billableDistanceKm: billable,
      baseFare: config.baseFare,
      perKmFare: config.perKmFare,
      distanceCharge: distanceCharge,
      roundingAdjustment: total - rawTotal,
      total: total,
      minimumApplied: minimumApplied,
    );
  }

  /// Angka tarif saja (kompatibel dengan pemanggil lama).
  static int estimate({required double distanceKm}) =>
      quote(distanceKm: distanceKm).total;
}
