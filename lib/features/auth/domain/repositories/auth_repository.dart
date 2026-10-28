import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';

/// Kontrak akses data autentikasi (diimplementasi di lapisan data).
abstract class AuthRepository {
  /// Emit `null` ketika pengguna keluar, dan [UserEntity] ketika masuk.
  Stream<UserEntity?> get authStateChanges;

  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  });

  Future<Either<Failure, UserEntity>> register({
    required String name,
    required String phone,
    required String email,
    required String password,
    required UserRole role,
  });

  Future<Either<Failure, Unit>> logout();
}
