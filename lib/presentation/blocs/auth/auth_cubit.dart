import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wordup/core/errors/app_auth_exception.dart';
import 'package:wordup/domain/repositories/auth_repository.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repo) : super(AuthInitial()) {
    _init();
  }

  final AuthRepository _repo;
  late final StreamSubscription<bool> _authSub;

  /// Called once on creation.
  /// Emits the current session state synchronously, then subscribes to
  /// Supabase onAuthStateChange — which fires on token refresh, sign-out,
  /// sign-in from another tab, etc.
  void _init() {
    // Synchronous check — Supabase SDK restores the stored session on init.
    emit(_repo.isAuthenticated ? AuthAuthenticated() : AuthUnauthenticated());

    _authSub = _repo.authStateChanges.listen((isAuth) {
      if (isClosed) return;
      emit(isAuth ? AuthAuthenticated() : AuthUnauthenticated());
    });
  }

  @override
  Future<void> close() async {
    await _authSub.cancel();
    return super.close();
  }

  // ── Auth actions ──────────────────────────────────────────────────────────

  Future<void> signInWithEmail(String email, String password) async {
    emit(AuthLoading());
    try {
      await _repo.signInWithEmail(email, password);
      // AuthAuthenticated will be emitted by _authSub when Supabase fires
      // onAuthStateChange — no need to emit AuthSuccess manually.
    } on AppAuthException catch (e) {
      emit(AuthError(e.message));
    } on Object catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> signUpWithEmail(String email, String password) async {
    emit(AuthLoading());
    try {
      await _repo.signUpWithEmail(email, password);
    } on AppAuthException catch (e) {
      emit(AuthError(e.message));
    } on Object catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> signInWithGoogle() async {
    emit(AuthLoading());
    try {
      await _repo.signInWithGoogle();
    } on AppAuthException catch (e) {
      emit(AuthError(e.message));
    } on Object catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> signInWithApple() async {
    emit(AuthLoading());
    try {
      await _repo.signInWithApple();
    } on AppAuthException catch (e) {
      emit(AuthError(e.message));
    } on Object catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> signOut() async {
    await _repo.signOut();
    // AuthUnauthenticated will be emitted by _authSub.
  }

  Future<void> sendPasswordReset(String email) async {
    emit(AuthLoading());
    try {
      await _repo.resetPassword(email);
      emit(AuthPasswordResetSent());
    } on AppAuthException catch (e) {
      emit(AuthError(e.message));
    } on Object catch (e) {
      emit(AuthError(e.toString()));
    }
  }
}
