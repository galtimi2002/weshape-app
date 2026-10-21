import 'dart:async';

import 'package:flutter/foundation.dart';

import 'app_user.dart';
import 'auth_service.dart';

enum AuthStatus { unknown, signedOut, signedIn }

class AuthController extends ChangeNotifier {
  AuthController(this._service);

  final AuthService _service;
  StreamSubscription<AppUser?>? _subscription;

  AuthStatus _status = AuthStatus.unknown;
  AppUser? _user;
  bool _busy = false;

  AuthStatus get status => _status;
  AppUser? get user => _user;
  bool get busy => _busy;
  AuthService get service => _service;

  Future<void> initialize() async {
    _subscription = _service.userChanges.listen(_onUserChanged);
    await _service.initialize();
    _onUserChanged(_service.currentUser);
  }

  void _onUserChanged(AppUser? user) {
    // Firebase also fires on token refreshes; only a real change matters here.
    final status = user == null ? AuthStatus.signedOut : AuthStatus.signedIn;
    if (status == _status && user?.uid == _user?.uid) return;
    _user = user;
    _status = status;
    notifyListeners();
  }

  /// Runs an auth action with [busy] on, so buttons can show progress and
  /// errors reach the caller untouched.
  Future<T> run<T>(Future<T> Function() action) async {
    _busy = true;
    notifyListeners();
    try {
      return await action();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> signOut() => run(_service.signOut);

  @override
  void dispose() {
    _subscription?.cancel();
    _service.dispose();
    super.dispose();
  }
}
