import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';

import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';
import '../../features/courier/presentation/bloc/courier_order_bloc.dart';
import '../../features/delivery/di/delivery_di.dart';
import '../../features/order/data/datasources/order_remote_data_source.dart';
import '../../features/order/data/repositories/order_repository_impl.dart';
import '../../features/order/domain/repositories/order_repository.dart';
import '../../features/order/presentation/bloc/order_bloc.dart';
import '../../features/admin/presentation/bloc/admin_bloc.dart';
import '../../features/payments/di/payments_di.dart';
import '../../features/wallet/di/wallet_di.dart';

/// Service locator global.
final GetIt sl = GetIt.instance;

/// Registrasi dependensi. Dipanggil sekali dari `main()` setelah
/// `Firebase.initializeApp` berhasil.
Future<void> initDependencies() async {
  // ---- Infrastruktur ----
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<FirebaseFirestore>(
    () => FirebaseFirestore.instance,
  );

  // ---- Auth (feature) ----
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(auth: sl(), firestore: sl()),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl()),
  );

  // AuthBloc dibuat singleton agar `AppRouter` bisa mendengarkan
  // stream autentikasi untuk redirect halaman.
  sl.registerLazySingleton<AuthBloc>(
    () => AuthBloc(authRepository: sl())..add(const AuthStarted()),
  );

  // ---- Order (feature) ----
  sl.registerLazySingleton<OrderRemoteDataSource>(
    () => OrderRemoteDataSourceImpl(firestore: sl()),
  );
  sl.registerLazySingleton<OrderRepository>(
    () => OrderRepositoryImpl(sl()),
  );

  // Factory: satu instance per halaman (stream menyesuaikan user aktif).
  sl.registerFactory<OrderBloc>(() => OrderBloc(orderRepository: sl()));
  sl.registerFactory<CourierOrderBloc>(
    () => CourierOrderBloc(orderRepository: sl()),
  );
  sl.registerFactory<AdminBloc>(() => AdminBloc(orderRepository: sl()));

  // ---- Delivery / Payments / Wallet (Person 2) ----
  registerDeliveryDependencies(sl);
  registerPaymentDependencies(sl);
  registerWalletDependencies(sl);
}
