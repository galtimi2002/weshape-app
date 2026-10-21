import 'package:flutter/widgets.dart';

/// A language the interface is translated into.
class AppLanguage {
  const AppLanguage(this.code, this.nativeName, this.flagCountry);

  /// ISO 639-1, the value stored on the user's profile.
  final String code;

  /// The language's own name, so people find theirs whatever is on screen now.
  final String nativeName;

  /// Whose flag stands for the language in the picker.
  final String flagCountry;

  /// Short label for tight spaces such as the header: EN, HU, ZH.
  String get shortCode => code.toUpperCase();

  String get flag => flagEmoji(flagCountry);

  Locale get locale => Locale(code);
}

/// Kept in step with SupportedLanguages.java in the backend.
abstract final class AppLanguages {
  static const String fallback = 'en';

  static const List<AppLanguage> all = <AppLanguage>[
    AppLanguage('en', 'English', 'GB'),
    AppLanguage('hu', 'Magyar', 'HU'),
    AppLanguage('ro', 'Română', 'RO'),
    AppLanguage('de', 'Deutsch', 'DE'),
    AppLanguage('fr', 'Français', 'FR'),
    AppLanguage('es', 'Español', 'ES'),
    AppLanguage('it', 'Italiano', 'IT'),
    AppLanguage('pt', 'Português', 'PT'),
    AppLanguage('nl', 'Nederlands', 'NL'),
    AppLanguage('pl', 'Polski', 'PL'),
    AppLanguage('hr', 'Hrvatski', 'HR'),
    AppLanguage('fi', 'Suomi', 'FI'),
    AppLanguage('sv', 'Svenska', 'SE'),
    AppLanguage('da', 'Dansk', 'DK'),
    AppLanguage('el', 'Ελληνικά', 'GR'),
    AppLanguage('ru', 'Русский', 'RU'),
    AppLanguage('tr', 'Türkçe', 'TR'),
    // Mandarin, written in simplified characters.
    AppLanguage('zh', '中文', 'CN'),
    AppLanguage('ja', '日本語', 'JP'),
  ];

  static final Map<String, AppLanguage> _byCode = {for (final l in all) l.code: l};

  static bool isSupported(String? code) => code != null && _byCode.containsKey(code);

  static AppLanguage of(String? code) => _byCode[code] ?? _byCode[fallback]!;

  /// The language a country starts with at registration. Only a suggestion:
  /// whatever the person picks afterwards wins.
  static String forCountry(String? country) =>
      _byCountry[country?.toUpperCase()] ?? fallback;

  static final Map<String, String> _byCountry = {
    for (final entry in <String, List<String>>{
      'hu': ['HU'],
      'ro': ['RO', 'MD'],
      'de': ['DE', 'AT', 'CH', 'LI'],
      'fr': ['FR', 'MC', 'LU', 'SN', 'CI', 'ML', 'BF', 'NE', 'TG', 'BJ', 'GN', 'CD', 'CG', 'CM', 'GA', 'MG', 'HT', 'CF', 'TD', 'DJ', 'KM', 'BI'],
      'es': ['ES', 'MX', 'AR', 'CO', 'CL', 'PE', 'VE', 'EC', 'GT', 'CU', 'BO', 'DO', 'HN', 'PY', 'SV', 'NI', 'CR', 'PA', 'UY', 'PR', 'GQ'],
      'it': ['IT', 'SM', 'VA'],
      'pt': ['PT', 'BR', 'AO', 'MZ', 'CV', 'GW', 'ST', 'TL'],
      'nl': ['NL', 'BE', 'SR'],
      'pl': ['PL'],
      'hr': ['HR', 'BA'],
      'fi': ['FI'],
      'sv': ['SE', 'AX'],
      'da': ['DK', 'GL', 'FO'],
      'el': ['GR', 'CY'],
      'ru': ['RU', 'BY', 'KZ', 'KG'],
      'tr': ['TR'],
      'zh': ['CN', 'TW', 'HK', 'MO'],
      'ja': ['JP'],
    }.entries)
      for (final country in entry.value) country: entry.key,
  };
}

/// 'HU' -> 🇭🇺. Built from regional indicator letters, so every ISO country
/// gets its flag without shipping 250 images.
String flagEmoji(String countryCode) {
  final code = countryCode.toUpperCase();
  if (code.length != 2) return '🏳️';
  const base = 0x1F1E6 - 0x41; // regional indicator A minus 'A'
  return String.fromCharCodes([base + code.codeUnitAt(0), base + code.codeUnitAt(1)]);
}
