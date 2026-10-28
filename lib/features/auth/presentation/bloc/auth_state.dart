import 'package:equatable/equatable.dart';

import '../../domain/entities/user_entity.dart';

/// Status global autentikasi (dipakai juga oleh redirect GoRouter).
enum AuthStatus { initial, loading, authenticated, unauthenticated, failure }

class AuthState extends Equatable {
  const AuthState({this.status = AuthStatus.initial, this.user, this.message});

  const AuthState.initial() : this();

  const AuthState.loading() : this(status: AuthStatus.loading);

  const AuthState.authenticated(UserEntity user)
      : this(status: AuthStatus.authenticated, user: user);

  const AuthState.unauthenticated()
      : this(status: AuthStatus.unauthenticated);

  const AuthState.failure(String message)
      : this(status: AuthStatus.failure, message: message);

  final AuthStatus status;
  final UserEntity? user;
  final String? message;

  @override
  List<Object?> get props => [status, user, message];
}
