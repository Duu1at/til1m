import 'package:til1m/domain/entities/user_settings.dart';

abstract interface class AuthRepository {
  Stream<bool> get authStateChanges;

  bool get isAuthenticated;

  bool get isGuest;

  String? get currentUserId;

  String? get currentUserEmail;

  String? get currentUserName;

  String? get currentUserAvatarUrl;

  Future<void> signInWithEmail(String email, String password);

  Future<bool> signUpWithEmail(String email, String password);

  Future<void> signInWithGoogle();

  Future<void> signInWithApple();

  Future<void> signOut();

  Future<void> resetPassword(String email);

  Future<void> migrateGuestProgress(String userId);

  Future<void> clearGuestLocalData();

  Future<void> clearAllLocalData();

  Future<UserSettings?> getUserSettings(String userId);

  Future<void> saveUserSettings(UserSettings settings);
}
