import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/constants/firestore_collections.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/user_entity.dart';
import '../models/user_model.dart';

/// Sumber data autentikasi: FirebaseAuth + dokumen profil di Firestore.
abstract class AuthRemoteDataSource {
  Stream<UserEntity?> get authStateChanges;

  Future<UserEntity> login({
    required String email,
    required String password,
  });

  Future<UserEntity> register({
    required String name,
    required String phone,
    required String email,
    required String password,
    required UserRole role,
  });

  Future<void> logout();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  })  : _auth = auth,
        _firestore = firestore;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  @override
  Stream<UserEntity?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      return _fetchProfile(firebaseUser);
    });
  }

  @override
  Future<UserEntity> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AuthException('Gagal masuk. Coba lagi.');
      }
      return _fetchProfile(user);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_authMessage(e));
    }
  }

  @override
  Future<UserEntity> register({
    required String name,
    required String phone,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AuthException('Pendaftaran gagal. Coba lagi.');
      }

      await user.updateDisplayName(name);
      final model = UserModel(
        uid: user.uid,
        name: name.trim(),
        email: email.trim(),
        phone: phone.trim(),
        role: role,
      );

      await _firestore
          .collection(FirestoreCollections.users)
          .doc(user.uid)
          .set({
        ...model.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      return model;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_authMessage(e));
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Gagal menyimpan data pengguna.');
    }
  }

  @override
  Future<void> logout() => _auth.signOut();

  /// Ambil profil dari Firestore; fallback ke data akun Auth bila dokumen
  /// belum ada (mis. akun dibuat sebelum fitur profil diluncurkan).
  Future<UserModel> _fetchProfile(User user) async {
    try {
      final doc = await _firestore
          .collection(FirestoreCollections.users)
          .doc(user.uid)
          .get();
      if (doc.exists) return UserModel.fromDoc(doc);
      return UserModel.fromAuthUser(
        uid: user.uid,
        name: user.displayName ?? '',
        email: user.email ?? '',
      );
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Gagal mengambil data profil.');
    }
  }

  String _authMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'user-disabled':
        return 'Akun ini dinonaktifkan.';
      case 'user-not-found':
        return 'Akun tidak ditemukan.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email atau kata sandi salah.';
      case 'email-already-in-use':
        return 'Email sudah terdaftar.';
      case 'weak-password':
        return 'Kata sandi terlalu lemah (minimal 6 karakter).';
      case 'network-request-failed':
        return 'Tidak ada koneksi internet.';
      default:
        return e.message ?? 'Terjadi kesalahan autentikasi.';
    }
  }
}
