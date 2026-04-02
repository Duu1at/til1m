import 'package:til1m/domain/entities/user_settings.dart';

abstract interface class AuthRepository {
  Stream<bool> get authStateChanges;
  bool get isAuthenticated;
  String? get currentUserId;
  Future<void> signInWithEmail(String email, String password);
  /// Returns true if email confirmation is required before the user can sign in.
  Future<bool> signUpWithEmail(String email, String password);
  Future<void> signInWithGoogle();
  Future<void> signInWithApple();
  Future<void> signOut();
  Future<void> resetPassword(String email);
  Future<void> migrateGuestProgress(String userId);
  Future<void> clearGuestLocalData();
  Future<UserSettings?> getUserSettings(String userId);
  Future<void> saveUserSettings(UserSettings settings);
}
