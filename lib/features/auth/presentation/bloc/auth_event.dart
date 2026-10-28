import 'package:equatable/equatable.dart';

import '../../domain/entities/user_entity.dart';

/// Event [AuthBloc].
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => const [];
}

/// Dipanggil sekali saat aplikasi start: subscribe stream auth.
class AuthStarted extends AuthEvent {
  const AuthStarted();
}

class AuthLoginRequested extends AuthEvent {
  const AuthLoginRequested({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

class AuthRegisterRequested extends AuthEvent {
  const AuthRegisterRequested({
    required this.name,
    required this.phone,
    required this.email,
    required this.password,
    required this.role,
  });

  final String name;
  final String phone;
  final String email;
  final String password;
  final UserRole role;

  @override
  List<Object?> get props => [name, phone, email, password, role];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

/// Dipublikasikan internal setiap kali stream auth berubah.
class AuthUserChanged extends AuthEvent {
  const AuthUserChanged(this.user);

  final UserEntity? user;

  @override
  List<Object?> get props => [user];
}
