import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/constants/app_constants.dart';
import 'core/di/injector.dart';

/// Entry point lokal untuk melihat aplikasi dengan Firebase Emulator Suite.
///
/// Jalankan emulator lebih dulu, lalu:
///
/// ```sh
/// # Web
/// flutter run -d chrome -t lib/main_emulator.dart --web-port=5000
///
/// # Android emulator
/// flutter run -d emulator-5554 -t lib/main_emulator.dart
/// ```
///
/// Data demo di-seed oleh `tool/seed_emulator.mjs`.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting(AppConstants.localeId);

  await Firebase.initializeApp(options: _demoOptions());

  // Android emulator menjangkau host lewat 10.0.2.2, web lewat loopback.
  const String host = kIsWeb ? '127.0.0.1' : '10.0.2.2';

  await FirebaseAuth.instance.useAuthEmulator(host, 9099);
  FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
  FirebaseFunctions.instance.useFunctionsEmulator(host, 5001);
  await FirebaseStorage.instance.useStorageEmulator(host, 9199);

  await initDependencies();
  runApp(const JenepontoKurirApp());
}

FirebaseOptions _demoOptions() {
  if (kIsWeb) {
    return const FirebaseOptions(
      apiKey: 'demo-api-key',
      appId: '1:1234567890:web:demo',
      messagingSenderId: '1234567890',
      projectId: 'demo-jeneponto',
      authDomain: 'demo-jeneponto.firebaseapp.com',
      storageBucket: 'demo-jeneponto.appspot.com',
    );
  }

  if (defaultTargetPlatform == TargetPlatform.android) {
    return const FirebaseOptions(
      apiKey: 'demo-api-key',
      appId: '1:1234567890:android:demo',
      messagingSenderId: '1234567890',
      projectId: 'demo-jeneponto',
      storageBucket: 'demo-jeneponto.appspot.com',
    );
  }

  throw UnsupportedError(
    'Demo emulator hanya dikonfigurasi untuk web dan Android.',
  );
}
