import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:til1m/core/errors/app_auth_exception.dart';
import 'package:til1m/domain/repositories/auth_repository.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repo) : super(AuthInitial()) {
    unawaited(_init());
  }

  final AuthRepository _repo;
  late final StreamSubscription<bool> _authSub;

  Future<void> _init() async {
    if (_repo.isAuthenticated) {
      emit(AuthAuthenticated());
    } else {
      final prefs = await SharedPreferences.getInstance();
      final isGuest = prefs.getBool(AppConstants.keyGuestMode) ?? false;
      if (!isClosed) emit(isGuest ? AuthGuest() : AuthUnauthenticated());
    }

    _authSub = _repo.authStateChanges.listen((isAuth) async {
      if (isClosed) return;
      if (isAuth) {
        final prefs = await SharedPreferences.getInstance();
        final wasGuest = prefs.getBool(AppConstants.keyGuestMode) ?? false;
        if (wasGuest) {
          final userId = _repo.currentUserId;
          if (userId != null) {
            await _repo.migrateGuestProgress(userId);
          }
          await _repo.clearGuestLocalData();
          await prefs.remove(AppConstants.keyGuestMode);
        }
        if (!isClosed) emit(AuthAuthenticated());
      } else {
        if (!isClosed) emit(AuthUnauthenticated());
      }
    });
  }

  @override
  Future<void> close() async {
    await _authSub.cancel();
    return super.close();
  }

  Future<void> signInWithEmail(String email, String password) async {
    emit(AuthLoading());
    try {
      await _repo.signInWithEmail(email, password);
    } on AppAuthException catch (e) {
      emit(AuthError(e.message));
    } on Object catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> signUpWithEmail(String email, String password) async {
    emit(AuthLoading());
    try {
      final needsConfirmation = await _repo.signUpWithEmail(email, password);
      if (needsConfirmation && !isClosed) {
        emit(AuthEmailConfirmationSent(email));
      }
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

  Future<void> continueAsGuest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyGuestMode, true);
    if (!isClosed) emit(AuthGuest());
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    final isGuest = prefs.getBool(AppConstants.keyGuestMode) ?? false;
    if (isGuest) {
      await _repo.clearGuestLocalData();
    }
    await prefs.remove(AppConstants.keyGuestMode);
    await _repo.signOut();
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
