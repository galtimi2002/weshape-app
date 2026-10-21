import 'app_user.dart';

/// What the UI codes against. Firebase in production; a local demo version so
/// the whole stack runs before the Firebase project exists.
abstract class AuthService {
  /// Restores any persisted session. Call once at startup.
  Future<void> initialize();

  AppUser? get currentUser;

  Stream<AppUser?> get userChanges;

  /// Bearer token for backend calls, or null when signed out.
  Future<String?> idToken({bool forceRefresh = false});

  /// [remember] false keeps the session only until the browser tab closes.
  Future<AppUser> signInWithEmail(String email, String password, {bool remember = true});

  Future<AppUser> registerWithEmail(String email, String password);

  Future<AppUser> signInWithGoogle();

  Future<void> sendPasswordReset(String email, {String? languageCode});

  Future<void> signOut();

  void dispose();
}
