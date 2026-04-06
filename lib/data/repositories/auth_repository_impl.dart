import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:til1m/core/constants/supabase_constants.dart';
import 'package:til1m/core/errors/app_auth_exception.dart';
import 'package:til1m/core/errors/auth_error_mapper.dart';
import 'package:til1m/domain/entities/user_settings.dart';
import 'package:til1m/domain/entities/word.dart';
import 'package:til1m/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl() : _supabase = Supabase.instance.client;

  final SupabaseClient _supabase;

  @override
  Stream<bool> get authStateChanges =>
      _supabase.auth.onAuthStateChange.map((data) => data.session != null);

  @override
  bool get isAuthenticated => _supabase.auth.currentSession != null;

  @override
  String? get currentUserId => _supabase.auth.currentUser?.id;

  @override
  String? get currentUserEmail => _supabase.auth.currentUser?.email;

  @override
  String? get currentUserName =>
      _supabase.auth.currentUser?.userMetadata?['full_name'] as String? ??
      _supabase.auth.currentUser?.userMetadata?['name'] as String?;

  @override
  String? get currentUserAvatarUrl =>
      _supabase.auth.currentUser?.userMetadata?['avatar_url'] as String?;

  @override
  Future<void> signInWithEmail(String email, String password) async {
    debugPrint('[Auth] signIn → email: $email');
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
      debugPrint(
        '[Auth] signIn success → user: ${_supabase.auth.currentUser?.id}',
      );
    } on AuthException catch (e) {
      debugPrint(
        '[Auth] signIn AuthException → ${e.message} (status: ${e.statusCode})',
      );
      throw AppAuthException(AuthErrorMapper.toLocaleKey(e.message, e.statusCode));
    } catch (e, st) {
      debugPrint('[Auth] signIn unexpected error → $e\n$st');
      rethrow;
    }
  }

  @override
  Future<bool> signUpWithEmail(String email, String password) async {
    debugPrint('[Auth] signUp → email: $email');
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      final needsConfirmation = response.session == null;
      debugPrint(
        '[Auth] signUp success → user: ${response.user?.id}, '
        'needsConfirmation: $needsConfirmation',
      );
      return needsConfirmation;
    } on AuthException catch (e) {
      debugPrint(
        '[Auth] signUp AuthException → ${e.message} (status: ${e.statusCode})',
      );
      throw AppAuthException(AuthErrorMapper.toLocaleKey(e.message, e.statusCode));
    } catch (e, st) {
      debugPrint('[Auth] signUp unexpected error → $e\n$st');
      rethrow;
    }
  }

  @override
  Future<void> signInWithGoogle() async {
    const webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
    debugPrint(
      '[Auth] signInWithGoogle → webClientId: ${webClientId.isEmpty ? "⚠️ EMPTY" : "present"}',
    );

    try {
      final googleUser = await GoogleSignIn(
        clientId:
            '919292740747-8ipmoan5nke1os8pu737q2uvmokf4a7q.apps.googleusercontent.com',
        serverClientId: webClientId,
      ).signIn();
      debugPrint(
        '[Auth] GoogleSignIn result → ${googleUser?.email ?? "null (user cancelled)"}',
      );
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;
      debugPrint('[Auth] idToken: ${idToken == null ? "⚠️ NULL" : "present"}');

      if (idToken == null || accessToken == null) {
        throw const AppAuthException('Failed to get Google token');
      }

      await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      debugPrint(
        '[Auth] signInWithGoogle success → user: ${_supabase.auth.currentUser?.id}',
      );
    } on AuthException catch (e) {
      debugPrint(
        '[Auth] signInWithGoogle AuthException → ${e.message} (status: ${e.statusCode})',
      );
      throw AppAuthException(AuthErrorMapper.toLocaleKey(e.message, e.statusCode));
    } catch (e, st) {
      debugPrint('[Auth] signInWithGoogle unexpected error → $e\n$st');
      rethrow;
    }
  }

  @override
  Future<void> signInWithApple() async {
    try {
      final rawNonce = _generateNonce();
      final hashedNonce = _sha256ofString(rawNonce);

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final idToken = credential.identityToken;
      if (idToken == null) {
        throw const AppAuthException('Failed to get Apple token');
      }

      await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );
    } on AuthException catch (e) {
      throw AppAuthException(AuthErrorMapper.toLocaleKey(e.message, e.statusCode));
    }
  }

  @override
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw AppAuthException(AuthErrorMapper.toLocaleKey(e.message, e.statusCode));
    }
  }

  @override
  Future<void> migrateGuestProgress(String userId) async {
    try {
      final progressBox = await Hive.openBox<dynamic>(AppConstants.hiveBoxProgress);
      if (progressBox.isNotEmpty) {
        final progressRows = progressBox.keys.map((key) {
          final raw = Map<String, dynamic>.from(progressBox.get(key) as Map);
          return {
            'user_id': userId,
            'word_id': key as String,
            'status': raw['status'] as String? ?? 'new',
            'ease_factor': (raw['ease_factor'] as num?)?.toDouble() ?? 2.5,
            'repetitions': raw['repetitions'] as int? ?? 0,
            'next_review_at': raw['next_review_at'] as String?,
            'last_reviewed_at': raw['last_reviewed_at'] as String?,
          };
        }).toList();

        await _supabase
            .from(SupabaseConstants.tableUserWordProgress)
            .upsert(progressRows, onConflict: 'user_id,word_id');
      }

      final favoritesBox = await Hive.openBox<dynamic>(AppConstants.hiveBoxFavorites);
      if (favoritesBox.isNotEmpty) {
        final favRows = favoritesBox.keys
            .map((wordId) => {'user_id': userId, 'word_id': wordId as String})
            .toList();
        await _supabase
            .from(SupabaseConstants.tableUserFavorites)
            .upsert(favRows, onConflict: 'user_id,word_id');
      }

      debugPrint(
        '[Auth] migrateGuestProgress done → '
        '${progressBox.length} progress, ${favoritesBox.length} favorites',
      );
    } catch (e, st) {
      debugPrint('[Auth] migrateGuestProgress error → $e\n$st');
      rethrow;
    }
  }

  @override
  Future<void> clearGuestLocalData() async {
    final progressBox = await Hive.openBox<dynamic>(AppConstants.hiveBoxProgress);
    await progressBox.clear();
    final favoritesBox = await Hive.openBox<dynamic>(AppConstants.hiveBoxFavorites);
    await favoritesBox.clear();
    debugPrint('[Auth] clearGuestLocalData done');
  }

  @override
  Future<UserSettings?> getUserSettings(String userId) async {
    try {
      final data = await _supabase
          .from(SupabaseConstants.tableUserSettings)
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (data == null) return null;

      return UserSettings(
        userId: data['user_id'] as String,
        dailyGoal: (data['daily_goal'] as int?) ?? 5,
        englishLevel: WordLevel.values.firstWhere(
          (l) =>
              l.name.toLowerCase() ==
              (data['english_level'] as String? ?? '').toLowerCase(),
          orElse: () => WordLevel.a1,
        ),
        uiLanguage: UiLanguage.values.firstWhere(
          (l) => l.name == (data['ui_language'] as String?),
          orElse: () => UiLanguage.ru,
        ),
        reminderTime: data['reminder_time'] as String?,
        theme: AppTheme.values.firstWhere(
          (t) => t.name == (data['theme'] as String?),
          orElse: () => AppTheme.system,
        ),
      );
    } catch (e, st) {
      debugPrint('[Auth] getUserSettings error → $e\n$st');
      rethrow;
    }
  }

  @override
  Future<void> saveUserSettings(UserSettings settings) async {
    try {
      await _supabase.from(SupabaseConstants.tableUserSettings).upsert({
        'user_id': settings.userId,
        'daily_goal': settings.dailyGoal,
        'english_level': settings.englishLevel.name.toUpperCase(),
        'ui_language': settings.uiLanguage.name,
        'reminder_time': settings.reminderTime,
        'theme': settings.theme.name,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } on AuthException catch (e) {
      throw AppAuthException(AuthErrorMapper.toLocaleKey(e.message, e.statusCode));
    } catch (e, st) {
      debugPrint('[Auth] saveUserSettings error → $e\n$st');
      rethrow;
    }
  }

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
