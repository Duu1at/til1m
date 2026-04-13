import 'package:til1m/domain/entities/user_settings.dart';

abstract interface class AuthRepository {
  Stream<bool> get authStateChanges;

  bool get isAuthenticated;

  String? get currentUserId;

  String? get currentUserEmail;

  String? get currentUserName;

  String? get currentUserAvatarUrl;

  Future<void> signInWithEmail(String email, String password);

  Future<bool> signUpWithEmail(String email, String password);

  Future<void> signInWithGoogle();

  Future<void> signInWithApple();

  Future<void> signOut();

  /// Deletes all personal data from Supabase and signs the user out.
  /// Full auth-user removal requires a server-side Edge Function.
  Future<void> deleteAccount();

  Future<void> resetPassword(String email);

  Future<void> clearAllLocalData();

  Future<UserSettings?> getUserSettings(String userId);

  Future<void> saveUserSettings(UserSettings settings);
}
