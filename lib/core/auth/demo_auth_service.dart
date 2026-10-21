import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'app_user.dart';
import 'auth_failure.dart';
import 'auth_service.dart';

/// Local stand-in for Firebase Authentication.
///
/// The backend is called with `dev:<uid>:<email>` tokens, which weshape-backend
/// accepts only while it runs with WESHAPE_AUTH_MODE=dev. Nothing here is
/// secure: it exists so the stack can be tried before Firebase is set up.
/// Any email plus an 8+ character password signs in.
class DemoAuthService implements AuthService {
  static const String _sessionKey = 'weshape.demo.session';

  final StreamController<AppUser?> _controller = StreamController<AppUser?>.broadcast();
  AppUser? _current;

  @override
  AppUser? get currentUser => _current;

  @override
  Stream<AppUser?> get userChanges => _controller.stream;

  @override
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sessionKey);
    if (raw != null) {
      try {
        _current = AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        await prefs.remove(_sessionKey);
      }
    }
    _controller.add(_current);
  }

  @override
  Future<String?> idToken({bool forceRefresh = false}) async {
    final user = _current;
    return user == null ? null : 'dev:${user.uid}:${user.email}';
  }

  @override
  Future<AppUser> signInWithEmail(String email, String password, {bool remember = true}) async {
    _requireEmail(email);
    if (password.length < 8) throw const AuthFailure(AuthFailureKind.invalidCredentials);
    return _signIn(AppUser(uid: _uidFor(email), email: email.trim().toLowerCase()), remember: remember);
  }

  @override
  Future<AppUser> registerWithEmail(String email, String password) async {
    _requireEmail(email);
    if (password.length < 8) throw const AuthFailure(AuthFailureKind.weakPassword);
    return _signIn(AppUser(uid: _uidFor(email), email: email.trim().toLowerCase()));
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _signIn(const AppUser(uid: 'demo-google', email: 'demo@weshape.energy', displayName: 'Demo User'));
  }

  @override
  Future<void> sendPasswordReset(String email, {String? languageCode}) async {
    _requireEmail(email);
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }

  @override
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    _current = null;
    _controller.add(null);
  }

  @override
  void dispose() => _controller.close();

  Future<AppUser> _signIn(AppUser user, {bool remember = true}) async {
    final prefs = await SharedPreferences.getInstance();
    if (remember) {
      await prefs.setString(_sessionKey, jsonEncode(user.toJson()));
    } else {
      await prefs.remove(_sessionKey);
    }
    _current = user;
    _controller.add(user);
    return user;
  }

  void _requireEmail(String email) {
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim())) {
      throw const AuthFailure(AuthFailureKind.invalidEmail);
    }
  }

  String _uidFor(String email) => 'demo-${email.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '-')}';
}
