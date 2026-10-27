import 'package:flutter_test/flutter_test.dart';
import 'package:jeneponto_kurir/features/delivery/domain/entities/coordinate.dart';
import 'package:jeneponto_kurir/features/delivery/domain/entities/jeneponto_service_area.dart';

void main() {
  group('JenepontoServiceArea', () {
    test('titik pusat kabupaten berada di area layanan', () {
      expect(
          JenepontoServiceArea.contains(JenepontoServiceArea.center), isTrue);
    });

    test('titik di luar Jeneponto ditolak', () {
      // Makassar.
      expect(
        JenepontoServiceArea.contains(const Coordinate(-5.1477, 119.4327)),
        isFalse,
      );
      // Titik dengan koordinat tidak valid.
      expect(
        JenepontoServiceArea.contains(const Coordinate(0, 0)),
        isFalse,
      );
    });

    test('menyediakan 11 kecamatan yang dilayani', () {
      expect(JenepontoServiceArea.districts.length, 11);
      expect(JenepontoServiceArea.districtNames, contains('Binamu'));
      expect(JenepontoServiceArea.districtNames, contains('Bangkala'));
      expect(JenepontoServiceArea.districtNames, contains('Tamalatea'));
    });

    test('mendeteksi kecamatan dari titik pusatnya', () {
      final JenepontoDistrict? binamu =
          JenepontoServiceArea.districtByName('Binamu');

      expect(binamu, isNotNull);
      expect(
        JenepontoServiceArea.districtAt(binamu!.center)?.name,
        'Binamu',
      );
    });

    test('districtByName tidak membedakan huruf besar/kecil', () {
      expect(JenepontoServiceArea.districtByName('binamu')?.name, 'Binamu');
      expect(JenepontoServiceArea.districtByName('  BINAMU  ')?.name, 'Binamu');
      expect(JenepontoServiceArea.districtByName('Tidak Ada'), isNull);
      expect(JenepontoServiceArea.districtByName(null), isNull);
    });

    test('nearestDistrict memberi fallback terdekat', () {
      final JenepontoDistrict nearest = JenepontoServiceArea.nearestDistrict(
        const Coordinate(-5.665, 119.741),
      );
      expect(nearest.name, 'Binamu');
    });

    test('poligon kecamatan punya minimal tiga titik', () {
      for (final district in JenepontoServiceArea.districts) {
        expect(district.boundary.length, greaterThanOrEqualTo(3));
      }
    });
  });
}
