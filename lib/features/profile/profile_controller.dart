import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/models/user_profile.dart';
import '../../core/settings/settings_controller.dart';
import '../../core/units/units.dart';

/// The signed-in person's profile, and the one place language, theme and
/// unit changes go through.
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

  /// How long a sleeping server is waited for: the free hosting tier puts it to sleep after a quiet
  /// spell, and starting it again can take a few minutes.
  static const wakeBudget = Duration(minutes: 3);

  /// How often it is asked again while it starts.
  static const wakeRetryEvery = Duration(seconds: 5);

  /// Bumped by [clear]: a load still waiting for the server stops when the person signs out.
  int _generation = 0;

  /// No answer, or the host's "starting" answers: the server is waking up, so ask again.
  static bool _waking(ApiException e) =>
      e.isNetwork || e.statusCode == 502 || e.statusCode == 503 || e.statusCode == 504;

  /// Loads the profile. While the server is waking up it asks again every [wakeRetryEvery], for up to
  /// [wakeBudget], with the start screen ("Starting the server …") showing; only then does the error
  /// with "Try again" show.
  Future<void> load() async {
    if (_loading) return;
    final generation = _generation;
    _loading = true;
    _error = null;
    notifyListeners();
    final deadline = DateTime.now().add(wakeBudget);
    try {
      while (true) {
        try {
          var profile = await _api.me();
          final draft = _pendingDraft;
          if (!profile.profileComplete && draft != null) {
            profile = await _api.completeProfile(draft);
          }
          if (generation != _generation) return;
          _pendingDraft = null;
          await _adopt(profile);
          return;
        } on ApiException catch (e) {
          if (generation != _generation) return;
          if (_waking(e) && DateTime.now().isBefore(deadline)) {
            await Future<void>.delayed(wakeRetryEvery);
            if (generation != _generation) return;
            continue;
          }
          _error = e;
          return;
        }
      }
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

  /// Metric or US units; null goes back to the country's usual ones.
  Future<void> changeUnits(UnitSystem? system) async {
    await _settings.setUnitSystem(system);
    if (_profile == null || _profile!.unitSystem == system) return;
    try {
      _profile = await _api.updatePreferences(unitSystem: unitSystemToApi(system) ?? 'AUTO');
    } on ApiException {
      // Kept on this device; the next change or sign-in tries again.
    }
  }

  void clear() {
    _generation++;
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
      await _settings.applyFromProfile(
        languageCode: profile.preferredLanguage,
        themeMode: profile.themeMode,
        unitSystem: profile.unitSystem,
        country: profile.country,
      );
    }
  }
}
