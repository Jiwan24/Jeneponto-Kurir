import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/wallet.dart';

/// Kontrak baca dompet kurir. Penulisan hanya dilakukan Cloud Function.
abstract class WalletRepository {
  Stream<Wallet> watchWallet(String uid);

  Stream<List<WalletTransaction>> watchTransactions(
    String uid, {
    int limit = 50,
  });

  Future<Either<Failure, Wallet>> fetchWallet(String uid);
}
