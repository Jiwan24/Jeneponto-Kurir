import 'dart:math' as math;

import 'package:equatable/equatable.dart';

/// Koordinat geografis sederhana (independen dari Firebase/Google Maps).
///
/// Nilai disimpan dalam derajat desimal (WGS84).
class Coordinate extends Equatable {
  const Coordinate(this.latitude, this.longitude);

  final double latitude;
  final double longitude;

  static const Coordinate zero = Coordinate(0, 0);

  bool get isValid =>
      latitude.isFinite &&
      longitude.isFinite &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;

  bool get isZero => latitude == 0 && longitude == 0;

  /// Jarak great-circle (haversine) ke [other] dalam kilometer.
  double distanceToKm(Coordinate other) {
    const double earthRadiusKm = 6371.0088;
    final double dLat = _toRadians(other.latitude - latitude);
    final double dLng = _toRadians(other.longitude - longitude);
    final double lat1 = _toRadians(latitude);
    final double lat2 = _toRadians(other.latitude);
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.sin(dLng / 2) *
            math.sin(dLng / 2) *
            math.cos(lat1) *
            math.cos(lat2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180;

  @override
  List<Object?> get props => [latitude, longitude];

  @override
  String toString() =>
      '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
}
