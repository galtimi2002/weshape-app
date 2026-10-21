import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weshape_app/core/settings/settings_controller.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('a first visit is English with the system theme', () async {
    final settings = SettingsController();
    await settings.load();
    expect(settings.languageCode, 'en');
    expect(settings.themeMode, ThemeMode.system);
  });

  test('language and theme are remembered on the device', () async {
    final first = SettingsController();
    await first.load();
    await first.setLanguage('fi');
    await first.setThemeMode(ThemeMode.dark);

    final next = SettingsController();
    await next.load();
    expect(next.languageCode, 'fi');
    expect(next.themeMode, ThemeMode.dark);
  });

  test('an unsupported language is ignored', () async {
    final settings = SettingsController();
    await settings.load();
    await settings.setLanguage('xx');
    expect(settings.languageCode, 'en');
  });
}
