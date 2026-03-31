import '../entities/user_settings.dart';

abstract class AuthRepository {
  Stream<bool> get authStateChanges;
  bool get isAuthenticated;
  String? get currentUserId;
  Future<void> signInWithEmail(String email, String password);
  Future<void> signUpWithEmail(String email, String password);
  Future<void> signInWithGoogle();
  Future<void> signOut();
  Future<void> resetPassword(String email);
  Future<void> migrateGuestProgress(String userId);
  Future<UserSettings?> getUserSettings(String userId);
  Future<void> saveUserSettings(UserSettings settings);
}
