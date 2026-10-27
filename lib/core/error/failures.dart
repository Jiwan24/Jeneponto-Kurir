import 'package:equatable/equatable.dart';

/// Tipe kegagalan yang dipakai di seluruh lapisan domain.
abstract class Failure extends Equatable {
  const Failure(this.message);

  /// Pesan yang aman ditampilkan ke pengguna (Bahasa Indonesia).
  final String message;

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([
    super.message = 'Terjadi gangguan pada server. Coba lagi.',
  ]);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'Tidak ada koneksi internet.',
  ]);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}
