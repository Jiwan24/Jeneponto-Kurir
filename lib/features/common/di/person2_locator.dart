import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';

import '../../delivery/di/delivery_di.dart';
import '../../payments/di/payments_di.dart';
import '../../wallet/di/wallet_di.dart';

/// Service locator lokal untuk modul Person 2.
final GetIt sl = GetIt.instance;

/// Registrasi dependensi Person 2. Panggil sekali dari bootstrap aplikasi
/// setelah `Firebase.initializeApp` berhasil.
Future<void> initPerson2Dependencies() async {
  if (!sl.isRegistered<FirebaseFirestore>()) {
    sl.registerLazySingleton<FirebaseFirestore>(
      () => FirebaseFirestore.instance,
    );
  }

  registerDeliveryDependencies(sl);
  registerPaymentDependencies(sl);
  registerWalletDependencies(sl);
}
