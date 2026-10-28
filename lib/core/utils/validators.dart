/// Validator input untuk form. Mengembalikan `null` bila valid.
class Validators {
  Validators._();

  static String? required(String? value, {String field = 'Kolom ini'}) {
    if (value == null || value.trim().isEmpty) {
      return '$field wajib diisi.';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email wajib diisi.';
    final RegExp regex = RegExp(r'^[\w\.\-+]+@([\w\-]+\.)+[A-Za-z]{2,}$');
    if (!regex.hasMatch(value.trim())) return 'Format email tidak valid.';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Kata sandi wajib diisi.';
    if (value.length < 6) return 'Kata sandi minimal 6 karakter.';
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

  static String? distanceKm(String? value) {
    if (value == null || value.trim().isEmpty) return 'Jarak wajib diisi.';
    final double? parsed =
        double.tryParse(value.replaceAll(',', '.').trim());
    if (parsed == null || parsed <= 0) {
      return 'Jarak harus angka lebih dari 0.';
    }
    return null;
  }
}
