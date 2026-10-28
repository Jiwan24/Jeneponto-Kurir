import 'package:intl/intl.dart';

import '../constants/app_constants.dart';

/// Format tampilan (mata uang, tanggal) untuk Bahasa Indonesia.
class Formatters {
  Formatters._();

  static final NumberFormat _currency = NumberFormat.currency(
    locale: AppConstants.localeId,
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final DateFormat _dateTime = DateFormat(
    'dd MMM yyyy, HH:mm',
    AppConstants.localeId,
  );

  static final DateFormat _date = DateFormat(
    'dd MMM yyyy',
    AppConstants.localeId,
  );

  /// 15000 -> "Rp 15.000"
  static String rupiah(num value) => _currency.format(value);

  /// DateTime -> "12 Okt 2026, 14:30"
  static String dateTime(DateTime value) => _dateTime.format(value.toLocal());

  /// DateTime -> "12 Okt 2026"
  static String date(DateTime value) => _date.format(value.toLocal());

  /// 3.5 -> "3,5 km"
  static String distance(double value) =>
      '${value.toStringAsFixed(1).replaceAll('.', ',')} km';
}
