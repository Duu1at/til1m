part of 'auth_cubit.dart';

sealed class AuthState {}

final class AuthInitial extends AuthState {}

final class AuthAuthenticated extends AuthState {}

/// User has a valid JWT but has not completed onboarding yet
/// (no user_settings row in Supabase). The router funnels this
/// state to /onboarding until [AuthAuthenticated] is emitted.
final class AuthNeedsOnboarding extends AuthState {}

final class AuthUnauthenticated extends AuthState {}

final class AuthGuest extends AuthState {}

final class AuthLoading extends AuthState {}

final class AuthPasswordResetSent extends AuthState {}

final class AuthEmailConfirmationSent extends AuthState {
  AuthEmailConfirmationSent(this.email);
  final String email;
}

final class AuthError extends AuthState {
  AuthError(this.message);

  final String message;
}
