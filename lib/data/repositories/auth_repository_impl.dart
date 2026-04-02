import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:til1m/core/errors/app_auth_exception.dart';
import 'package:til1m/domain/entities/user_settings.dart';
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
      throw AppAuthException(e.message);
    } catch (e, st) {
      debugPrint('[Auth] signIn unexpected error → $e\n$st');
      rethrow;
    }
  }

  @override
  Future<void> signUpWithEmail(String email, String password) async {
    debugPrint('[Auth] signUp → email: $email');
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      debugPrint('[Auth] signUp success → user: ${response.user?.id}');
    } on AuthException catch (e) {
      debugPrint(
        '[Auth] signUp AuthException → ${e.message} (status: ${e.statusCode})',
      );
      throw AppAuthException(e.message);
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
      throw AppAuthException(e.message);
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
      throw AppAuthException(e.message);
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
      throw AppAuthException(e.message);
    }
  }

  @override
  Future<void> migrateGuestProgress(String userId) async {}

  @override
  Future<UserSettings?> getUserSettings(String userId) async {
    return null;
  }

  @override
  Future<void> saveUserSettings(UserSettings settings) async {}

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
