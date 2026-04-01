part of 'auth_cubit.dart';

sealed class AuthState {}

final class AuthInitial extends AuthState {}

final class AuthAuthenticated extends AuthState {}

final class AuthUnauthenticated extends AuthState {}

final class AuthLoading extends AuthState {}

final class AuthPasswordResetSent extends AuthState {}

final class AuthError extends AuthState {
  AuthError(this.message);

  final String message;
}
