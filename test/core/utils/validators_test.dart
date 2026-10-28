import 'package:flutter_test/flutter_test.dart';
import 'package:jeneponto_kurir/core/utils/validators.dart';

void main() {
  group('Validators.required', () {
    test('menolak nilai kosong', () {
      expect(Validators.required(null), isNotNull);
      expect(Validators.required('   '), isNotNull);
    });

    test('menerima nilai terisi', () {
      expect(Validators.required('Jeneponto'), isNull);
    });
  });

  group('Validators.email', () {
    test('email valid', () {
      expect(Validators.email('budi@mail.com'), isNull);
    });

    test('email tidak valid', () {
      expect(Validators.email('budi@mail'), isNotNull);
      expect(Validators.email('tanpa-atmail.com'), isNotNull);
    });
  });

  group('Validators.password', () {
    test('minimal 6 karakter', () {
      expect(Validators.password('12345'), isNotNull);
      expect(Validators.password('123456'), isNull);
    });
  });

  group('Validators.phone', () {
    test('nomor HP Indonesia', () {
      expect(Validators.phone('081234567890'), isNull);
      expect(Validators.phone('123'), isNotNull);
    });
  });

  group('Validators.distanceKm', () {
    test('menerima desimal koma', () {
      expect(Validators.distanceKm('4,5'), isNull);
      expect(Validators.distanceKm('0'), isNotNull);
      expect(Validators.distanceKm('abc'), isNotNull);
    });
  });
}
