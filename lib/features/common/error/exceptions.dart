/// Exception teknis yang dilempar lapisan data Person 2.
class ServerException implements Exception {
  const ServerException(this.message);
  final String message;
}
