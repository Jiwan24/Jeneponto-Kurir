/// Exception teknis yang dilempar lapisan data.
///
/// Diubah menjadi [Failure] oleh repository sebelum sampai ke bloc/UI,
/// sehingga bloc tidak pernah bergantung pada exception Firebase.
class ServerException implements Exception {
  const ServerException(this.message);
  final String message;
}

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
}
