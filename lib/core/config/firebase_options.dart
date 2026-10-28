import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Konfigurasi Firebase.
///
/// File ini masih berisi placeholder. Ganti dengan hasil perintah:
///
/// ```sh
/// dart pub global activate flutterfire_cli
/// flutterfire configure --project=jeneponto-kurir
/// ```
///
/// Perintah di atas akan menimpa file ini dengan nilai asli dari Firebase
/// Console untuk Android, iOS, (opsional) web dan platform lain.
class DefaultFirebaseOptions {
  DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'Platform ini belum dikonfigurasi. Jalankan `flutterfire configure`.',
        );
    }
  }

  // TODO: isi nilai berikut dari Firebase Console sebelum rilis.
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'ISI_API_KEY_ANDROID',
    appId: 'ISI_APP_ID_ANDROID',
    messagingSenderId: 'ISI_SENDER_ID',
    projectId: 'jeneponto-kurir',
    storageBucket: 'jeneponto-kurir.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'ISI_API_KEY_IOS',
    appId: 'ISI_APP_ID_IOS',
    messagingSenderId: 'ISI_SENDER_ID',
    projectId: 'jeneponto-kurir',
    storageBucket: 'jeneponto-kurir.appspot.com',
    iosBundleId: 'com.jeneponto.kurir',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'ISI_API_KEY_WEB',
    appId: 'ISI_APP_ID_WEB',
    messagingSenderId: 'ISI_SENDER_ID',
    projectId: 'jeneponto-kurir',
    storageBucket: 'jeneponto-kurir.appspot.com',
  );
}
