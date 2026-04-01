part of 'auth_cubit.dart';

sealed class AuthState {}

/// Initial state — session check not yet completed.
final class AuthInitial extends AuthState {}

/// Session is active (user is logged in).
final class AuthAuthenticated extends AuthState {}

/// No active session (logged out or expired).
final class AuthUnauthenticated extends AuthState {}

/// A sign-in / sign-up / OAuth action is in progress.
final class AuthLoading extends AuthState {}

/// Password reset email was sent.
final class AuthPasswordResetSent extends AuthState {}

/// An auth action failed.
final class AuthError extends AuthState {
  AuthError(this.message);

  final String message;
}
