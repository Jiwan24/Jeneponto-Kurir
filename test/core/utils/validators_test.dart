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

    test('menolak jarak di luar batas layanan', () {
      expect(Validators.distanceKm('0,4'), isNotNull);
      expect(Validators.distanceKm('30'), isNull);
      expect(Validators.distanceKm('30,1'), isNotNull);
    });
  });

  group('Validators.personName', () {
    test('menerima nama orang yang wajar', () {
      expect(Validators.personName('Budi Santoso'), isNull);
      expect(Validators.personName("Ahmad Ma'ruf"), isNull);
      expect(Validators.personName('Siti-Annisa'), isNull);
    });

    test('menolak nama kosong, terlalu pendek, atau berisi angka', () {
      expect(Validators.personName(null), isNotNull);
      expect(Validators.personName('A'), isNotNull);
      expect(Validators.personName('Budi 123'), isNotNull);
    });
  });

  group('Validators.addressDetail', () {
    test('menerima alamat lengkap', () {
      expect(Validators.addressDetail('Jl. Sultan Hasanuddin No. 10'), isNull);
    });

    test('menolak alamat terlalu pendek atau kosong', () {
      expect(Validators.addressDetail(null), isNotNull);
      expect(Validators.addressDetail('Jl. A'), isNotNull);
    });
  });

  group('Validators.weightKg', () {
    test('berat opsional memakai nilai default', () {
      expect(Validators.weightKg(''), isNull);
      expect(Validators.weightKg(null, defaultValue: null), isNotNull);
    });

    test('menerima 0,1 sampai 50 kg', () {
      expect(Validators.weightKg('0,1'), isNull);
      expect(Validators.weightKg('50'), isNull);
      expect(Validators.weightKg('0,05'), isNotNull);
      expect(Validators.weightKg('51'), isNotNull);
      expect(Validators.weightKg('berat'), isNotNull);
    });
  });

  group('Validators.itemNotes', () {
    test('catatan boleh kosong', () {
      expect(Validators.itemNotes(null), isNull);
      expect(Validators.itemNotes('  '), isNull);
    });

    test('catatan dibatasi 200 karakter', () {
      expect(Validators.itemNotes('a' * 200), isNull);
      expect(Validators.itemNotes('a' * 201), isNotNull);
    });
  });

  group('Validators lokasi', () {
    test('titik wajib dipilih', () {
      expect(Validators.pointSelected(false), isNotNull);
      expect(Validators.pointSelected(true), isNull);
    });

    test('titik wajib berada di area layanan', () {
      expect(Validators.serviceArea(false), isNotNull);
      expect(Validators.serviceArea(true), isNull);
    });

    test('kecamatan wajib dipilih', () {
      expect(Validators.district(null), isNotNull);
      expect(Validators.district(''), isNotNull);
      expect(Validators.district('Binamu'), isNull);
    });
  });
}
