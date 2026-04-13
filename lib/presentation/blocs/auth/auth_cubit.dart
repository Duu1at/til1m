import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:til1m/core/errors/app_auth_exception.dart';
import 'package:til1m/domain/entities/user_settings.dart';
import 'package:til1m/domain/entities/word.dart';
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
      // Fast cold-start check using the local flag — no network call needed.
      // The detailed Supabase check (getUserSettings) runs in _authSub on the
      // next actual sign-in, not on every TOKEN_REFRESHED event.
      final prefs = await SharedPreferences.getInstance();
      final onboardingDone =
          prefs.getBool(AppConstants.keyOnboardingDone) ?? false;
      if (!isClosed) {
        emit(onboardingDone ? AuthAuthenticated() : AuthNeedsOnboarding());
      }
    } else {
      if (!isClosed) emit(AuthUnauthenticated());
    }

    _authSub = _repo.authStateChanges.listen((isAuth) async {
      if (isClosed) return;
      if (isAuth) {
        // Guard: TOKEN_REFRESHED and INITIAL_SESSION events must not re-run
        // the onboarding check when the user is already in a stable state.
        // The check only needs to run on real sign-in transitions
        // (state was AuthLoading or AuthUnauthenticated before the event).
        if (state is AuthAuthenticated || state is AuthNeedsOnboarding) return;

        final prefs = await SharedPreferences.getInstance();

        final onboardingDone =
            prefs.getBool(AppConstants.keyOnboardingDone) ?? false;
        if (!onboardingDone) {
          // No local onboarding — user signed up directly via OAuth without
          // going through the WelcomeScreen flow (e.g. direct Google sign-up).
          if (!isClosed) emit(AuthNeedsOnboarding());
          return;
        }

        // Onboarding was done locally (WelcomeScreen → onboarding → register
        // flow). Settings are in SharedPreferences but may not be in Supabase
        // yet (e.g. email confirmation happened after the onboarding step).
        // Sync them now; this is a no-op for returning users whose settings
        // already exist.
        final userId = _repo.currentUserId;
        if (userId != null) {
          try {
            final existing = await _repo.getUserSettings(userId);
            if (existing == null) {
              await _repo.saveUserSettings(_buildLocalSettings(userId, prefs));
            }
          } on Object catch (e, st) {
            // Non-fatal: the user can still use the app. Sync will be
            // retried on the next sign-in when existing == null again.
            debugPrint('[AuthCubit] settings sync failed → $e\n$st');
          }
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

  String? get currentUserEmail => _repo.currentUserEmail;
  String? get currentUserName => _repo.currentUserName;
  String? get currentUserAvatarUrl => _repo.currentUserAvatarUrl;

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
      return;
    } on Object catch (e) {
      emit(AuthError(e.toString()));
      return;
    }
    // If the repo returned without authenticating (e.g. user cancelled),
    // restore the previous state.
    if (!isClosed && !_repo.isAuthenticated) {
      if (!isClosed) emit(AuthUnauthenticated());
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

  /// Called at the end of onboarding when the user is already authenticated
  /// ([AuthNeedsOnboarding] state — e.g. direct OAuth sign-up).
  /// Saves [settings] to Supabase and transitions to [AuthAuthenticated].
  /// The router then redirects to /home automatically.
  Future<void> completeAuthenticatedOnboarding(UserSettings settings) async {
    final userId = _repo.currentUserId;
    if (userId == null) {
      emit(AuthError('auth/no-user'));
      return;
    }
    emit(AuthLoading());
    try {
      await _repo.saveUserSettings(settings.copyWith(userId: userId));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.keyOnboardingDone, true);
      if (!isClosed) emit(AuthAuthenticated());
    } on Object catch (e) {
      if (!isClosed) emit(AuthError(e.toString()));
    }
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    // Clear all Hive caches regardless of user type (guest or authenticated).
    // Prevents data leakage between accounts on shared devices.
    await _repo.clearAllLocalData();
    // Remove personal SharedPreferences keys. keyLanguageSelected,
    // keyUiLanguage and keyOnboardingDone are intentionally kept:
    // the language choice should survive re-login, and keeping
    // keyOnboardingDone ensures a cold start after sign-out goes to /login
    // (via router redirect) instead of /welcome.
    await prefs.remove(AppConstants.keyUserLevel);
    await prefs.remove(AppConstants.keyDailyGoal);
    await prefs.remove(AppConstants.keyReminderTime);
    await prefs.remove(AppConstants.keyStudyTimeFrom);
    await prefs.remove(AppConstants.keyStudyTimeTo);
    await prefs.remove(AppConstants.keyPendingAuth);
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

  /// Builds a [UserSettings] from values stored in SharedPreferences by the
  /// onboarding screen. Used when syncing local onboarding data to Supabase
  /// after the email-registration + confirmation flow.
  UserSettings _buildLocalSettings(String userId, SharedPreferences prefs) {
    final levelName =
        prefs.getString(AppConstants.keyUserLevel) ?? WordLevel.a1.name;
    final goal = prefs.getInt(AppConstants.keyDailyGoal) ?? 5;
    final uiLangName =
        prefs.getString(AppConstants.keyUiLanguage) ?? UiLanguage.ru.name;
    final themeName =
        prefs.getString(AppConstants.keyTheme) ?? AppTheme.system.name;

    return UserSettings(
      userId: userId,
      dailyGoal: goal,
      englishLevel: WordLevel.values.firstWhere(
        (l) => l.name == levelName,
        orElse: () => WordLevel.a1,
      ),
      uiLanguage: UiLanguage.values.firstWhere(
        (l) => l.name == uiLangName,
        orElse: () => UiLanguage.ru,
      ),
      theme: AppTheme.values.firstWhere(
        (t) => t.name == themeName,
        orElse: () => AppTheme.system,
      ),
    );
  }
}
