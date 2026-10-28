/// Daftar nama collection di Firestore.
///
/// Jangan mengubah nama collection setelah aplikasi rilis:
/// data lama akan terputus dari aplikasi baru.
class FirestoreCollections {
  FirestoreCollections._();

  static const String users = 'users';
  static const String orders = 'orders';
}
