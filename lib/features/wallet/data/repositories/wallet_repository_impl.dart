import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/wallet.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../datasources/wallet_remote_data_source.dart';

class WalletRepositoryImpl implements WalletRepository {
  WalletRepositoryImpl(this._remote);

  final WalletRemoteDataSource _remote;

  @override
  Stream<Wallet> watchWallet(String uid) => _remote.watchWallet(uid);

  @override
  Stream<List<WalletTransaction>> watchTransactions(
    String uid, {
    int limit = 50,
  }) =>
      _remote.watchTransactions(uid, limit: limit);

  @override
  Future<Either<Failure, Wallet>> fetchWallet(String uid) async {
    try {
      return Right(await _remote.fetchWallet(uid));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }
}
