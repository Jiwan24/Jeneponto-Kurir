import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/config/firebase_options.dart';
import 'core/constants/app_constants.dart';
import 'core/di/injector.dart';
import 'core/widgets/setup_required_app.dart';

/// True bila `Firebase.initializeApp` sukses.
/// Dipakai untuk menampilkan panduan konfigurasi bila gagal.
bool firebaseReady = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Data lokal untuk format tanggal/mata uang Bahasa Indonesia.
  await initializeDateFormatting(AppConstants.localeId);

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseReady = true;
  } catch (error, stackTrace) {
    debugPrint('Firebase gagal diinisialisasi: $error');
    debugPrint(stackTrace.toString());
  }

  if (!firebaseReady) {
    runApp(const SetupRequiredApp());
    return;
  }

  await initDependencies();
  runApp(const JenepontoKurirApp());
}
