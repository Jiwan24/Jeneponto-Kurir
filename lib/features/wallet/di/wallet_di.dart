import 'package:get_it/get_it.dart';

import '../data/datasources/wallet_remote_data_source.dart';
import '../data/repositories/wallet_repository_impl.dart';
import '../domain/repositories/wallet_repository.dart';
import '../presentation/bloc/wallet_bloc.dart';

/// Registrasi dependensi fitur dompet kurir (baca-saja di client).
void registerWalletDependencies(GetIt sl) {
  sl.registerLazySingleton<WalletRemoteDataSource>(
    () => WalletRemoteDataSourceImpl(firestore: sl()),
  );
  sl.registerLazySingleton<WalletRepository>(
    () => WalletRepositoryImpl(sl()),
  );
  sl.registerFactory<WalletBloc>(
    () => WalletBloc(repository: sl()),
  );
}
