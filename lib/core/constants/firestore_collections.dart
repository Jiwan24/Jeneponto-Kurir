/// Daftar nama collection di Firestore.
///
/// Jangan mengubah nama collection setelah aplikasi rilis:
/// data lama akan terputus dari aplikasi baru.
class FirestoreCollections {
  FirestoreCollections._();

  static const String users = 'users';
  static const String orders = 'orders';

  /// Catatan pembayaran per pesanan (`payments/{orderId}`).
  static const String payments = 'payments';

  /// Saldo dompet kurir (`wallets/{uid}`).
  static const String wallets = 'wallets';

  /// Mutasi dompet kurir (`wallet_transactions/{id}`).
  static const String walletTransactions = 'wallet_transactions';

  /// Konfigurasi global (`config/finance`, `config/app`).
  static const String config = 'config';
}
