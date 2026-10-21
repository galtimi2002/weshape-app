import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/models/user_profile.dart';
import '../../core/settings/settings_controller.dart';

/// The signed-in person's profile, and the one place language and theme
/// changes go through.
///
/// Changing either while signed in updates the screen at once and saves to
/// the profile in the background, so the choice follows the person to any
/// device. Signed out, the choice is only remembered on this device.
class ProfileController extends ChangeNotifier {
  ProfileController(this._api, this._settings);

  final ApiClient _api;
  final SettingsController _settings;

  UserProfile? _profile;
  ApiException? _error;
  bool _loading = false;

  /// Collected by the registration form before the Firebase account exists,
  /// sent as soon as the backend knows the new user.
  ProfileDraft? _pendingDraft;

  UserProfile? get profile => _profile;
  ApiException? get error => _error;
  bool get isLoading => _loading;
  bool get isLoaded => _profile != null;
  bool get needsProfile => _profile != null && !_profile!.profileComplete;

  void setPendingRegistration(ProfileDraft draft) => _pendingDraft = draft;

  /// Registration failed (email taken, say): the draft must not end up on
  /// whichever account signs in next.
  void clearPendingRegistration() => _pendingDraft = null;

  Future<void> load() async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      var profile = await _api.me();
      final draft = _pendingDraft;
      if (!profile.profileComplete && draft != null) {
        profile = await _api.completeProfile(draft);
      }
      _pendingDraft = null;
      await _adopt(profile);
    } on ApiException catch (e) {
      _error = e;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Used by the "one more step" screen after a first Google sign-in.
  Future<void> completeProfile(ProfileDraft draft) async {
    await _adopt(await _api.completeProfile(draft));
    notifyListeners();
  }

  Future<void> changeLanguage(String code) async {
    await _settings.setLanguage(code);
    if (_profile == null || _profile!.preferredLanguage == code) return;
    try {
      _profile = await _api.updatePreferences(language: code);
    } on ApiException {
      // Kept on this device; the next change or sign-in tries again.
    }
  }

  Future<void> changeTheme(ThemeMode mode) async {
    await _settings.setThemeMode(mode);
    if (_profile == null || _profile!.themeMode == mode) return;
    try {
      _profile = await _api.updatePreferences(themeMode: themeModeToApi(mode));
    } on ApiException {
      // Kept on this device; the next change or sign-in tries again.
    }
  }

  void clear() {
    _profile = null;
    _error = null;
    _pendingDraft = null;
    notifyListeners();
  }

  Future<void> _adopt(UserProfile profile) async {
    _profile = profile;
    // A brand-new Google account still carries the server defaults (English,
    // system theme). Applying those would undo what the person picked on the
    // login page a moment ago, so only a finished profile takes over.
    if (profile.profileComplete) {
      await _settings.applyFromProfile(languageCode: profile.preferredLanguage, themeMode: profile.themeMode);
    }
  }
}
