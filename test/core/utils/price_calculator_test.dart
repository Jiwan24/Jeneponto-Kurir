import 'package:flutter_test/flutter_test.dart';
import 'package:jeneponto_kurir/core/utils/price_calculator.dart';

void main() {
  group('PriceCalculator.estimate', () {
    test('tarif dasar + per km (jarak bulat)', () {
      // 8000 + (4 * 2500) = 18000
      expect(PriceCalculator.estimate(distanceKm: 4), 18000);
    });

    test('jarak di bawah 1 km tetap dihitung 1 km', () {
      // 8000 + (1 * 2500) = 10500
      expect(PriceCalculator.estimate(distanceKm: 0.5), 10500);
    });

    test('dibulatkan ke atas per Rp500', () {
      // 8000 + (2.3 * 2500) = 13750 -> 14000
      expect(PriceCalculator.estimate(distanceKm: 2.3), 14000);
    });

    test('jarak nol aman (tetap minimum 1 km)', () {
      expect(PriceCalculator.estimate(distanceKm: 0), 10500);
    });
  });

  group('PriceCalculator.quote', () {
    test('merinci tarif dasar, jarak, dan pembulatan', () {
      final FareBreakdown fare = PriceCalculator.quote(distanceKm: 2.3);

      expect(fare.baseFare, 8000);
      expect(fare.perKmFare, 2500);
      expect(fare.billableDistanceKm, 2.3);
      expect(fare.distanceCharge, 5750);
      // 13750 dibulatkan ke atas menjadi 14000.
      expect(fare.roundingAdjustment, 250);
      expect(fare.total, 14000);
      expect(fare.minimumApplied, isFalse);
    });

    test('menandai jarak minimum yang diterapkan', () {
      final FareBreakdown fare = PriceCalculator.quote(distanceKm: 0.4);

      expect(fare.billableDistanceKm, 1);
      expect(fare.minimumApplied, isTrue);
      expect(fare.total, 10500);
    });

    test('jarak negatif atau tidak terhingga memakai minimum', () {
      expect(PriceCalculator.quote(distanceKm: -2).total, 10500);
      expect(
        PriceCalculator.quote(distanceKm: double.nan).minimumApplied,
        isTrue,
      );
      expect(
        PriceCalculator.quote(distanceKm: double.infinity).total,
        10500,
      );
    });

    test('konfigurasi tarif kustom dipakai konsisten', () {
      const FareConfig config = FareConfig(
        baseFare: 10000,
        perKmFare: 3000,
        minimumDistanceKm: 2,
        roundingStep: 1000,
      );
      final FareBreakdown fare = PriceCalculator.quote(
        distanceKm: 1.5,
        config: config,
      );

      expect(fare.billableDistanceKm, 2);
      expect(fare.distanceCharge, 6000);
      expect(fare.total, 16000);
      expect(fare.minimumApplied, isTrue);
    });

    test('FareBreakdown dapat diserialisasi dan dibaca kembali', () {
      final FareBreakdown original = PriceCalculator.quote(distanceKm: 3.2);
      final FareBreakdown restored = FareBreakdown.fromMap(original.toMap());

      expect(restored.toMap(), original.toMap());
    });
  });
}
