import '../constants/app_constants.dart';

/// Perhitungan tarif pengiriman (MVP: jarak diketik manual).
///
/// rumus: (baseFare + jarak * perKmFare) dibulatkan ke atas per Rp500,
/// dengan jarak minimum 1 km.
class PriceCalculator {
  PriceCalculator._();

  static int estimate({required double distanceKm}) {
    final double billable = distanceKm < AppConstants.minimumDistanceKm
        ? AppConstants.minimumDistanceKm
        : distanceKm;
    final double raw =
        AppConstants.baseFare + (billable * AppConstants.perKmFare);
    final int step = AppConstants.priceRoundingStep;
    return (raw / step).ceil() * step;
  }
}
