import 'package:intl/intl.dart';

import '../constants/app_constants.dart';

/// Format tampilan mata uang, tanggal, dan jarak untuk Person 2.
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

  static String rupiah(num value) => _currency.format(value);

  static String dateTime(DateTime value) => _dateTime.format(value.toLocal());

  static String date(DateTime value) => _date.format(value.toLocal());

  static String distance(double value) =>
      '${value.toStringAsFixed(1).replaceAll('.', ',')} km';
}
