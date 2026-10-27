import 'package:get_it/get_it.dart';

import '../data/datasources/delivery_remote_data_source.dart';
import '../data/repositories/delivery_repository_impl.dart';
import '../domain/repositories/delivery_repository.dart';
import '../presentation/bloc/delivery_checkout_bloc.dart';
import '../presentation/bloc/delivery_history_bloc.dart';
import '../presentation/bloc/delivery_order_bloc.dart';

/// Registrasi dependensi fitur delivery/pemesanan pelanggan.
void registerDeliveryDependencies(GetIt sl) {
  sl.registerLazySingleton<DeliveryRemoteDataSource>(
    () => DeliveryRemoteDataSourceImpl(firestore: sl()),
  );
  sl.registerLazySingleton<DeliveryRepository>(
    () => DeliveryRepositoryImpl(sl()),
  );

  sl.registerFactory<DeliveryCheckoutBloc>(
    () => DeliveryCheckoutBloc(repository: sl()),
  );
  sl.registerFactory<DeliveryOrderBloc>(
    () => DeliveryOrderBloc(repository: sl()),
  );
  sl.registerFactory<DeliveryHistoryBloc>(
    () => DeliveryHistoryBloc(repository: sl()),
  );
}
