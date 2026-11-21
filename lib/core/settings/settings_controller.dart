import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../i18n/languages.dart';
import '../units/units.dart';

/// Language, theme and units as they apply on this device right now.
///
/// Stored locally so the login page already opens in the last language and
/// theme used here. Once someone signs in, their profile is the source of
/// truth and is copied in with [applyFromProfile]; see ProfileController.
class SettingsController extends ChangeNotifier {
  static const String _languageKey = 'weshape.language';
  static const String _themeKey = 'weshape.themeMode';
  static const String _unitsKey = 'weshape.units';

  String _languageCode = AppLanguages.fallback;
  ThemeMode _themeMode = ThemeMode.system;
  bool _loaded = false;

  /// Units picked by hand; null follows [_country].
  UnitSystem? _units;
  String? _country;

  String get languageCode => _languageCode;
  Locale get locale => Locale(_languageCode);
  AppLanguage get language => AppLanguages.of(_languageCode);
  ThemeMode get themeMode => _themeMode;
  bool get isLoaded => _loaded;

  /// The units on screen: the ones picked, or else the usual ones in the person's country.
  UnitSystem get unitSystem => _units ?? defaultUnitSystemFor(_country);

  /// The person's country (ISO 3166-1 alpha-2), for the units and measures usual there.
  String? get country => _country;

  /// Units picked by hand, or null when they follow the country.
  UnitSystem? get unitSystemChoice => _units;

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
    _units = unitSystemFromApi(prefs.getString(_unitsKey));
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

  /// Picks units by hand; null goes back to the country's usual ones.
  Future<void> setUnitSystem(UnitSystem? system) async {
    if (system == _units) return;
    _units = system;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final value = unitSystemToApi(system);
    if (value == null) {
      await prefs.remove(_unitsKey);
    } else {
      await prefs.setString(_unitsKey, value);
    }
  }

  /// The country whose usual units apply while none are picked by hand.
  void setCountry(String? country) {
    if (country == _country) return;
    final before = unitSystem;
    _country = country;
    if (unitSystem != before) notifyListeners();
  }

  Future<void> applyFromProfile({
    required String languageCode,
    required ThemeMode themeMode,
    UnitSystem? unitSystem,
    String? country,
  }) async {
    setCountry(country);
    await setLanguage(languageCode);
    await setThemeMode(themeMode);
    // Units picked on another device follow the person; none picked there keeps this device's choice.
    if (unitSystem != null) await setUnitSystem(unitSystem);
  }

  /// The brightness actually on screen, resolving "system" against the device.
  Brightness effectiveBrightness(BuildContext context) => switch (_themeMode) {
        ThemeMode.light => Brightness.light,
        ThemeMode.dark => Brightness.dark,
        ThemeMode.system => MediaQuery.platformBrightnessOf(context),
      };
}
