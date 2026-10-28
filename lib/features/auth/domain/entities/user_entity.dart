import 'package:equatable/equatable.dart';

/// Peran pengguna aplikasi.
enum UserRole {
  customer('Customer'),
  courier('Kurir'),
  admin('Admin');

  const UserRole(this.label);
  final String label;

  static UserRole fromString(String? value) {
    return UserRole.values.firstWhere(
      (role) => role.name == value,
      orElse: () => UserRole.customer,
    );
  }
}

/// Data pengguna yang dipakai seluruh lapisan (tanpa dependensi Firebase).
class UserEntity extends Equatable {
  const UserEntity({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.photoUrl,
  });

  final String uid;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final String? photoUrl;

  bool get isCustomer => role == UserRole.customer;
  bool get isCourier => role == UserRole.courier;
  bool get isAdmin => role == UserRole.admin;

  @override
  List<Object?> get props => [uid, name, email, phone, role, photoUrl];
}
