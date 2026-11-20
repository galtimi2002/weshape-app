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

  /// English first, then the rest in alphabetical order of the name the list shows (each language's
  /// own name, accents ignored); the other scripts follow the Latin ones. English being first also
  /// makes it the fallback in Flutter's locale matching.
  static const List<AppLanguage> all = <AppLanguage>[
    AppLanguage('en', 'English', 'GB'),
    AppLanguage('id', 'Bahasa Indonesia', 'ID'),
    AppLanguage('ms', 'Bahasa Melayu', 'MY'),
    AppLanguage('bs', 'Bosanski', 'BA'),
    AppLanguage('ca', 'Català', 'AD'),
    AppLanguage('cs', 'Čeština', 'CZ'),
    AppLanguage('cy', 'Cymraeg', 'GB'),
    AppLanguage('da', 'Dansk', 'DK'),
    AppLanguage('de', 'Deutsch', 'DE'),
    AppLanguage('et', 'Eesti', 'EE'),
    AppLanguage('es', 'Español', 'ES'),
    AppLanguage('eu', 'Euskara', 'ES'),
    // Filipino (based on Tagalog); ISO 639-1 code tl.
    AppLanguage('tl', 'Filipino', 'PH'),
    AppLanguage('fr', 'Français', 'FR'),
    AppLanguage('ga', 'Gaeilge', 'IE'),
    AppLanguage('gl', 'Galego', 'ES'),
    AppLanguage('ha', 'Hausa', 'NG'),
    AppLanguage('hr', 'Hrvatski', 'HR'),
    AppLanguage('is', 'Íslenska', 'IS'),
    AppLanguage('it', 'Italiano', 'IT'),
    AppLanguage('sw', 'Kiswahili', 'KE'),
    AppLanguage('lv', 'Latviešu', 'LV'),
    AppLanguage('lb', 'Lëtzebuergesch', 'LU'),
    AppLanguage('lt', 'Lietuvių', 'LT'),
    AppLanguage('hu', 'Magyar', 'HU'),
    AppLanguage('mt', 'Malti', 'MT'),
    AppLanguage('nl', 'Nederlands', 'NL'),
    // Norwegian Bokmål, the written standard most people use.
    AppLanguage('nb', 'Norsk', 'NO'),
    AppLanguage('pl', 'Polski', 'PL'),
    AppLanguage('pt', 'Português', 'PT'),
    AppLanguage('ro', 'Română', 'RO'),
    AppLanguage('sq', 'Shqip', 'AL'),
    AppLanguage('sk', 'Slovenčina', 'SK'),
    AppLanguage('sl', 'Slovenščina', 'SI'),
    AppLanguage('fi', 'Suomi', 'FI'),
    AppLanguage('sv', 'Svenska', 'SE'),
    AppLanguage('vi', 'Tiếng Việt', 'VN'),
    AppLanguage('tr', 'Türkçe', 'TR'),
    AppLanguage('yo', 'Yorùbá', 'NG'),
    AppLanguage('el', 'Ελληνικά', 'GR'),
    AppLanguage('be', 'Беларуская', 'BY'),
    AppLanguage('bg', 'Български', 'BG'),
    AppLanguage('mk', 'Македонски', 'MK'),
    AppLanguage('ru', 'Русский', 'RU'),
    // Serbian in Cyrillic, its official script.
    AppLanguage('sr', 'Српски', 'RS'),
    AppLanguage('uk', 'Українська', 'UA'),
    // Written right to left.
    AppLanguage('ur', 'اردو', 'PK'),
    // Written right to left; Flutter mirrors the layout on its own.
    AppLanguage('ar', 'العربية', 'SA'),
    // Written right to left.
    AppLanguage('fa', 'فارسی', 'IR'),
    AppLanguage('ne', 'नेपाली', 'NP'),
    AppLanguage('hi', 'हिन्दी', 'IN'),
    AppLanguage('bn', 'বাংলা', 'BD'),
    // Punjabi in Gurmukhi script.
    AppLanguage('pa', 'ਪੰਜਾਬੀ', 'IN'),
    AppLanguage('th', 'ไทย', 'TH'),
    AppLanguage('my', 'မြန်မာ', 'MM'),
    AppLanguage('am', 'አማርኛ', 'ET'),
    // Mandarin, written in simplified characters.
    AppLanguage('zh', '中文', 'CN'),
    AppLanguage('ja', '日本語', 'JP'),
    AppLanguage('ko', '한국어', 'KR'),
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
      'hr': ['HR'],
      'fi': ['FI'],
      'sv': ['SE', 'AX'],
      'da': ['DK', 'GL', 'FO'],
      'el': ['GR', 'CY'],
      'ru': ['RU', 'BY', 'KZ', 'KG'],
      'tr': ['TR'],
      'zh': ['CN', 'TW', 'HK', 'MO'],
      'ja': ['JP'],
      'ko': ['KR'],
      'hi': ['IN'],
      'bn': ['BD'],
      'id': ['ID'],
      'vi': ['VN'],
      'ar': ['SA', 'AE', 'EG', 'MA', 'DZ', 'TN', 'JO', 'QA', 'KW', 'OM', 'BH', 'LB', 'IQ', 'LY', 'SY', 'YE', 'SD', 'PS', 'MR'],
      'cs': ['CZ'],
      'bg': ['BG'],
      'sk': ['SK'],
      'lt': ['LT'],
      'sl': ['SI'],
      'lv': ['LV'],
      'et': ['EE'],
      'mt': ['MT'],
      'uk': ['UA'],
      'sr': ['RS', 'ME'],
      'nb': ['NO', 'SJ'],
      'sq': ['AL', 'XK'],
      'mk': ['MK'],
      'bs': ['BA'],
      'ca': ['AD'],
      'is': ['IS'],
      'ur': ['PK'],
      'sw': ['KE', 'TZ'],
      'fa': ['IR', 'AF'],
      'th': ['TH'],
      'ms': ['MY', 'BN'],
      'am': ['ET'],
      'my': ['MM'],
      'ne': ['NP'],
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
