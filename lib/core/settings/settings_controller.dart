import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../i18n/languages.dart';

/// Language and theme as they apply on this device right now.
///
/// Stored locally so the login page already opens in the last language and
/// theme used here. Once someone signs in, their profile is the source of
/// truth and is copied in with [applyFromProfile]; see ProfileController.
class SettingsController extends ChangeNotifier {
  static const String _languageKey = 'weshape.language';
  static const String _themeKey = 'weshape.themeMode';

  String _languageCode = AppLanguages.fallback;
  ThemeMode _themeMode = ThemeMode.system;
  bool _loaded = false;

  String get languageCode => _languageCode;
  Locale get locale => Locale(_languageCode);
  AppLanguage get language => AppLanguages.of(_languageCode);
  ThemeMode get themeMode => _themeMode;
  bool get isLoaded => _loaded;

  /// English on a first visit, whatever the browser says: that is the agreed
  /// default, and registration then suggests the country's language.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_languageKey);
    if (AppLanguages.isSupported(saved)) _languageCode = saved!;
    _themeMode = switch (prefs.getString(_themeKey)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    _loaded = true;
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    if (!AppLanguages.isSupported(code) || code == _languageCode) return;
    _languageCode = code;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, code);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode.name);
  }

  Future<void> applyFromProfile({required String languageCode, required ThemeMode themeMode}) async {
    await setLanguage(languageCode);
    await setThemeMode(themeMode);
  }

  /// The brightness actually on screen, resolving "system" against the device.
  Brightness effectiveBrightness(BuildContext context) => switch (_themeMode) {
        ThemeMode.light => Brightness.light,
        ThemeMode.dark => Brightness.dark,
        ThemeMode.system => MediaQuery.platformBrightnessOf(context),
      };
}
