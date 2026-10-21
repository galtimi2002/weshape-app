import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

import 'app_user.dart';
import 'auth_failure.dart';
import 'auth_service.dart';

/// Production identity provider. Firebase holds the passwords (hashed) and
/// handles Google sign-in; the backend only ever sees the resulting ID token.
class FirebaseAuthService implements AuthService {
  FirebaseAuthService({fb.FirebaseAuth? auth}) : _auth = auth ?? fb.FirebaseAuth.instance;

  final fb.FirebaseAuth _auth;

  @override
  Future<void> initialize() async {
    // Firebase restores the session itself. Waiting for the first event means
    // a returning user is not flashed the login screen while that happens.
    await _auth.authStateChanges().first;
  }

  @override
  AppUser? get currentUser => _map(_auth.currentUser);

  @override
  Stream<AppUser?> get userChanges => _auth.authStateChanges().map(_map);

  @override
  Future<String?> idToken({bool forceRefresh = false}) async {
    final user = _auth.currentUser;
    if (user == null) return null;
    try {
      return await user.getIdToken(forceRefresh);
    } on fb.FirebaseAuthException catch (e) {
      throw _translate(e);
    }
  }

  @override
  Future<AppUser> signInWithEmail(String email, String password, {bool remember = true}) async {
    try {
      if (kIsWeb) {
        await _auth.setPersistence(remember ? fb.Persistence.LOCAL : fb.Persistence.SESSION);
      }
      final cred = await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
      return _require(cred.user);
    } on fb.FirebaseAuthException catch (e) {
      throw _translate(e);
    }
  }

  @override
  Future<AppUser> registerWithEmail(String email, String password) async {
    try {
      if (kIsWeb) await _auth.setPersistence(fb.Persistence.LOCAL);
      final cred = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
      return _require(cred.user);
    } on fb.FirebaseAuthException catch (e) {
      throw _translate(e);
    }
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final provider = fb.GoogleAuthProvider()
          ..addScope('email')
          ..setCustomParameters({'prompt': 'select_account'});
        final cred = await _auth.signInWithPopup(provider);
        return _require(cred.user);
      }
      final account = await GoogleSignIn(scopes: const ['email']).signIn();
      if (account == null) throw const AuthFailure(AuthFailureKind.cancelled);
      final googleAuth = await account.authentication;
      final credential = fb.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      return _require((await _auth.signInWithCredential(credential)).user);
    } on fb.FirebaseAuthException catch (e) {
      throw _translate(e);
    }
  }

  @override
  Future<void> sendPasswordReset(String email, {String? languageCode}) async {
    try {
      // The reset email arrives in the language the person is using.
      if (languageCode != null) await _auth.setLanguageCode(languageCode);
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on fb.FirebaseAuthException catch (e) {
      throw _translate(e);
    }
  }

  @override
  Future<void> signOut() async {
    if (!kIsWeb) {
      try {
        await GoogleSignIn().signOut();
      } catch (_) {
        // Not signed in with Google.
      }
    }
    await _auth.signOut();
  }

  @override
  void dispose() {}

  AppUser? _map(fb.User? user) =>
      user == null ? null : AppUser(uid: user.uid, email: user.email, displayName: user.displayName);

  AppUser _require(fb.User? user) =>
      _map(user) ?? (throw const AuthFailure(AuthFailureKind.unknown, 'Firebase returned no user'));

  AuthFailure _translate(fb.FirebaseAuthException e) => switch (e.code) {
        'invalid-credential' || 'wrong-password' || 'user-not-found' || 'invalid-login-credentials' =>
          const AuthFailure(AuthFailureKind.invalidCredentials),
        'email-already-in-use' => const AuthFailure(AuthFailureKind.emailInUse),
        'weak-password' => const AuthFailure(AuthFailureKind.weakPassword),
        'invalid-email' => const AuthFailure(AuthFailureKind.invalidEmail),
        'too-many-requests' => const AuthFailure(AuthFailureKind.tooManyRequests),
        'network-request-failed' => const AuthFailure(AuthFailureKind.network),
        'popup-closed-by-user' || 'cancelled-popup-request' => const AuthFailure(AuthFailureKind.cancelled),
        _ => AuthFailure(AuthFailureKind.unknown, e.code),
      };
}
