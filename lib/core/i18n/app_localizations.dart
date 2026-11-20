import 'package:flutter/material.dart';

import 'app_strings.dart';
import 'languages.dart';
import 'strings/strings_am.dart';
import 'strings/strings_ar.dart';
import 'strings/strings_be.dart';
import 'strings/strings_bg.dart';
import 'strings/strings_bn.dart';
import 'strings/strings_bs.dart';
import 'strings/strings_ca.dart';
import 'strings/strings_cs.dart';
import 'strings/strings_cy.dart';
import 'strings/strings_da.dart';
import 'strings/strings_de.dart';
import 'strings/strings_el.dart';
import 'strings/strings_en.dart';
import 'strings/strings_es.dart';
import 'strings/strings_et.dart';
import 'strings/strings_eu.dart';
import 'strings/strings_fa.dart';
import 'strings/strings_fi.dart';
import 'strings/strings_fr.dart';
import 'strings/strings_ga.dart';
import 'strings/strings_gl.dart';
import 'strings/strings_ha.dart';
import 'strings/strings_hi.dart';
import 'strings/strings_hr.dart';
import 'strings/strings_hu.dart';
import 'strings/strings_id.dart';
import 'strings/strings_is.dart';
import 'strings/strings_it.dart';
import 'strings/strings_ja.dart';
import 'strings/strings_ko.dart';
import 'strings/strings_lb.dart';
import 'strings/strings_lt.dart';
import 'strings/strings_lv.dart';
import 'strings/strings_mk.dart';
import 'strings/strings_ms.dart';
import 'strings/strings_mt.dart';
import 'strings/strings_my.dart';
import 'strings/strings_nb.dart';
import 'strings/strings_ne.dart';
import 'strings/strings_nl.dart';
import 'strings/strings_pa.dart';
import 'strings/strings_pl.dart';
import 'strings/strings_pt.dart';
import 'strings/strings_ro.dart';
import 'strings/strings_ru.dart';
import 'strings/strings_sk.dart';
import 'strings/strings_sl.dart';
import 'strings/strings_sq.dart';
import 'strings/strings_sr.dart';
import 'strings/strings_sv.dart';
import 'strings/strings_sw.dart';
import 'strings/strings_th.dart';
import 'strings/strings_tl.dart';
import 'strings/strings_tr.dart';
import 'strings/strings_uk.dart';
import 'strings/strings_ur.dart';
import 'strings/strings_vi.dart';
import 'strings/strings_yo.dart';
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
    'id': kStringsId,
    'ms': kStringsMs,
    'bs': kStringsBs,
    'ca': kStringsCa,
    'cs': kStringsCs,
    'cy': kStringsCy,
    'da': kStringsDa,
    'de': kStringsDe,
    'et': kStringsEt,
    'es': kStringsEs,
    'eu': kStringsEu,
    'tl': kStringsTl,
    'fr': kStringsFr,
    'ga': kStringsGa,
    'gl': kStringsGl,
    'ha': kStringsHa,
    'hr': kStringsHr,
    'is': kStringsIs,
    'it': kStringsIt,
    'sw': kStringsSw,
    'lv': kStringsLv,
    'lb': kStringsLb,
    'lt': kStringsLt,
    'hu': kStringsHu,
    'mt': kStringsMt,
    'nl': kStringsNl,
    'nb': kStringsNb,
    'pl': kStringsPl,
    'pt': kStringsPt,
    'ro': kStringsRo,
    'sq': kStringsSq,
    'sk': kStringsSk,
    'sl': kStringsSl,
    'fi': kStringsFi,
    'sv': kStringsSv,
    'vi': kStringsVi,
    'tr': kStringsTr,
    'yo': kStringsYo,
    'el': kStringsEl,
    'be': kStringsBe,
    'bg': kStringsBg,
    'mk': kStringsMk,
    'ru': kStringsRu,
    'sr': kStringsSr,
    'uk': kStringsUk,
    'ur': kStringsUr,
    'ar': kStringsAr,
    'fa': kStringsFa,
    'ne': kStringsNe,
    'hi': kStringsHi,
    'bn': kStringsBn,
    'pa': kStringsPa,
    'th': kStringsTh,
    'my': kStringsMy,
    'am': kStringsAm,
    'zh': kStringsZh,
    'ja': kStringsJa,
    'ko': kStringsKo,
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
