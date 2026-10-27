import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_collections.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/wallet.dart';
import '../models/wallet_model.dart';

/// Akses baca dompet kurir. Penulisan dilakukan Cloud Function.
abstract class WalletRemoteDataSource {
  Stream<Wallet> watchWallet(String uid);

  Stream<List<WalletTransaction>> watchTransactions(
    String uid, {
    int limit = 50,
  });

  Future<Wallet> fetchWallet(String uid);
}

class WalletRemoteDataSourceImpl implements WalletRemoteDataSource {
  WalletRemoteDataSourceImpl({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  @override
  Stream<Wallet> watchWallet(String uid) {
    if (uid.isEmpty) return Stream.value(Wallet.empty(''));
    return _firestore
        .collection(FirestoreCollections.wallets)
        .doc(uid)
        .snapshots()
        .map(
          (doc) => doc.exists ? WalletModel.fromDoc(doc) : Wallet.empty(uid),
        );
  }

  @override
  Stream<List<WalletTransaction>> watchTransactions(
    String uid, {
    int limit = 50,
  }) {
    if (uid.isEmpty) {
      return Stream.value(const <WalletTransaction>[]);
    }
    return _firestore
        .collection(FirestoreCollections.walletTransactions)
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(WalletTransactionModel.fromDoc)
              .toList(growable: false),
        );
  }

  @override
  Future<Wallet> fetchWallet(String uid) async {
    if (uid.isEmpty) return Wallet.empty('');
    try {
      final doc = await _firestore
          .collection(FirestoreCollections.wallets)
          .doc(uid)
          .get();
      return doc.exists ? WalletModel.fromDoc(doc) : Wallet.empty(uid);
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Gagal memuat dompet.');
    }
  }
}
