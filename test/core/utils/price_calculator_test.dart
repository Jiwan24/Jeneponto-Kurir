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
}
