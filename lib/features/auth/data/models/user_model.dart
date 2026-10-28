import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/user_entity.dart';

/// Representasi dokumen `users/{uid}` di Firestore.
class UserModel extends UserEntity {
  const UserModel({
    required super.uid,
    required super.name,
    required super.email,
    required super.phone,
    required super.role,
    super.photoUrl,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String? ?? '',
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      role: UserRole.fromString(map['role'] as String?),
      photoUrl: map['photoUrl'] as String?,
    );
  }

  factory UserModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return UserModel.fromMap({...?doc.data(), 'uid': doc.id});
  }

  /// Profil minimum dari akun Auth ketika dokumen profil belum ada.
  factory UserModel.fromAuthUser({
    required String uid,
    String name = '',
    String email = '',
    UserRole role = UserRole.customer,
  }) {
    return UserModel(uid: uid, name: name, email: email, phone: '', role: role);
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.name,
      'photoUrl': photoUrl,
    };
  }
}
