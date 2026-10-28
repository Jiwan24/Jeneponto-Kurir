import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:jeneponto_kurir/demo/demo_app.dart';
import 'package:jeneponto_kurir/demo/demo_repositories.dart';
import 'package:jeneponto_kurir/features/common/constants/app_constants.dart';

/// Entry point demo Person 2.
///
/// Modul asli tidak punya `main.dart` karena hanya berisi fitur. File ini
/// adalah "host aplikasi" minimal: tanpa Firebase, tanpa login, dan memakai
/// repository in-memory supaya seluruh alur Person 2 bisa dicoba di emulator.
///
/// Jalankan:
///
/// ```sh
/// flutter run -d emulator-5554 -t lib/main.dart
/// flutter build apk --debug
/// ```
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting(AppConstants.localeId);
  registerDemoDependencies();
  runApp(const DemoApp());
}
