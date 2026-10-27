import 'package:cloud_functions/cloud_functions.dart';
import 'package:get_it/get_it.dart';

import 'package:jeneponto_kurir/features/common/constants/app_constants.dart';
import '../data/datasources/payment_remote_data_source.dart';
import '../data/repositories/payment_repository_impl.dart';
import '../domain/repositories/payment_repository.dart';
import '../presentation/bloc/payment_bloc.dart';

/// Registrasi dependensi fitur pembayaran (Midtrans + COD).
void registerPaymentDependencies(GetIt sl) {
  sl.registerLazySingleton<FirebaseFunctions>(
    () => FirebaseFunctions.instanceFor(
      region: AppConstants.functionsRegion,
    ),
  );
  sl.registerLazySingleton<PaymentRemoteDataSource>(
    () => PaymentRemoteDataSourceImpl(
      firestore: sl(),
      functions: sl(),
    ),
  );
  sl.registerLazySingleton<PaymentRepository>(
    () => PaymentRepositoryImpl(sl()),
  );
  sl.registerFactory<PaymentBloc>(
    () => PaymentBloc(repository: sl()),
  );
}
