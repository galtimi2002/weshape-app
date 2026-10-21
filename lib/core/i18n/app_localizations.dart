import 'package:flutter/material.dart';

import 'app_strings.dart';
import 'languages.dart';
import 'strings/strings_de.dart';
import 'strings/strings_en.dart';
import 'strings/strings_es.dart';
import 'strings/strings_fi.dart';
import 'strings/strings_fr.dart';
import 'strings/strings_hr.dart';
import 'strings/strings_hu.dart';
import 'strings/strings_it.dart';
import 'strings/strings_nl.dart';
import 'strings/strings_pl.dart';
import 'strings/strings_pt.dart';
import 'strings/strings_ro.dart';
import 'strings/strings_ru.dart';
import 'strings/strings_tr.dart';
import 'strings/strings_zh.dart';

/// Hand-rolled localization: no code generation step, so `flutter run` works
/// straight from a clone. Texts live in tool/translations.py.
class AppLocalizations {
  const AppLocalizations(this.locale, this.strings);

  final Locale locale;
  final AppStrings strings;

  static final List<Locale> supportedLocales = [for (final l in AppLanguages.all) l.locale];

  static const Map<String, AppStrings> byLanguageCode = <String, AppStrings>{
    'en': kStringsEn,
    'hu': kStringsHu,
    'ro': kStringsRo,
    'de': kStringsDe,
    'fr': kStringsFr,
    'es': kStringsEs,
    'it': kStringsIt,
    'pt': kStringsPt,
    'nl': kStringsNl,
    'pl': kStringsPl,
    'hr': kStringsHr,
    'fi': kStringsFi,
    'ru': kStringsRu,
    'tr': kStringsTr,
    'zh': kStringsZh,
  };

  static AppStrings stringsFor(Locale locale) => byLanguageCode[locale.languageCode] ?? kStringsEn;

  static bool isSupported(Locale locale) => byLanguageCode.containsKey(locale.languageCode);

  static AppStrings of(BuildContext context) {
    final instance = Localizations.of<AppLocalizations>(context, AppLocalizations);
    return instance?.strings ?? kStringsEn;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();
}

/// Shorthand: `context.t.signIn`
extension AppLocalizationsX on BuildContext {
  AppStrings get t => AppLocalizations.of(this);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.isSupported(locale);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale, AppLocalizations.stringsFor(locale));

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
