import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weshape_app/core/i18n/app_localizations.dart';
import 'package:weshape_app/core/i18n/countries.dart';
import 'package:weshape_app/core/i18n/country_names.g.dart';
import 'package:weshape_app/core/i18n/languages.dart';

void main() {
  test('fifteen languages, English first, each with its strings', () {
    expect(AppLanguages.all, hasLength(15));
    expect(AppLanguages.all.first.code, 'en');
    expect(AppLocalizations.supportedLocales, hasLength(15));
    for (final lang in AppLanguages.all) {
      expect(AppLocalizations.byLanguageCode.containsKey(lang.code), isTrue, reason: lang.code);
    }
  });

  test('every language has a greeting with the name filled in', () {
    for (final lang in AppLanguages.all) {
      final greeting = AppLocalizations.stringsFor(Locale(lang.code)).greet('Ada');
      expect(greeting, contains('Ada'), reason: lang.code);
      expect(greeting, isNot(contains('{name}')), reason: lang.code);
    }
  });

  test('translations are really translated', () {
    final english = AppLocalizations.stringsFor(const Locale('en')).signIn;
    for (final lang in AppLanguages.all.where((l) => l.code != 'en')) {
      expect(AppLocalizations.stringsFor(lang.locale).signIn, isNot(english), reason: lang.code);
    }
    expect(AppLocalizations.stringsFor(const Locale('hu')).signIn, 'Bejelentkezés');
    expect(AppLocalizations.stringsFor(const Locale('zh')).signIn, '登录');
  });

  test('unknown languages fall back to English', () {
    expect(AppLocalizations.stringsFor(const Locale('xx')).signIn, 'Sign in');
    expect(AppLanguages.of('xx').code, 'en');
  });

  test('countries map to their language, everything else to English', () {
    expect(AppLanguages.forCountry('HU'), 'hu');
    expect(AppLanguages.forCountry('md'), 'ro');
    expect(AppLanguages.forCountry('AT'), 'de');
    expect(AppLanguages.forCountry('BE'), 'nl');
    expect(AppLanguages.forCountry('BR'), 'pt');
    expect(AppLanguages.forCountry('TW'), 'zh');
    expect(AppLanguages.forCountry('SE'), 'en');
    expect(AppLanguages.forCountry(null), 'en');
  });

  test('country names exist in every language', () {
    for (final lang in AppLanguages.all) {
      expect(kCountryNames[lang.code], isNotNull, reason: lang.code);
      expect(kCountryNames[lang.code]!.length, kCountryCodes.length, reason: lang.code);
    }
    expect(Countries.nameOf('HU', 'hu'), 'Magyarország');
    expect(Countries.nameOf('DE', 'fr'), 'Allemagne');
  });

  test('country search ignores case and accents and also matches English', () {
    final hungary = Country('HU', Countries.nameOf('HU', 'hu'));
    expect(Countries.matches(hungary, 'magyar'), isTrue);
    expect(Countries.matches(hungary, 'MAGYARORSZAG'), isTrue);
    expect(Countries.matches(hungary, 'hungary'), isTrue);
    expect(Countries.matches(hungary, 'hu'), isTrue);
    expect(Countries.matches(hungary, 'román'), isFalse);
  });

  test('flags are built from the country code', () {
    expect(flagEmoji('HU'), '🇭🇺');
    expect(flagEmoji('gb'), '🇬🇧');
  });
}
