import 'country_names.g.dart';
import 'languages.dart';

/// A country as the picker shows it, named in the current interface language.
class Country {
  const Country(this.code, this.name);

  /// ISO 3166-1 alpha-2, upper case. What gets stored on the profile.
  final String code;
  final String name;

  String get flag => flagEmoji(code);
}

abstract final class Countries {
  static String nameOf(String code, String languageCode) =>
      kCountryNames[languageCode]?[code] ?? kCountryNames['en']![code] ?? code;

  /// Every country, sorted by its name in [languageCode].
  static List<Country> sorted(String languageCode) {
    final list = [for (final c in kCountryCodes) Country(c, nameOf(c, languageCode))];
    list.sort((a, b) => _fold(a.name).compareTo(_fold(b.name)));
    return list;
  }

  /// Matches on the localized name, the English name and the code, ignoring
  /// case and accents, so "magyar", "hungary" and "hu" all find Hungary.
  static bool matches(Country country, String query) {
    final q = _fold(query.trim());
    if (q.isEmpty) return true;
    return _fold(country.name).contains(q) ||
        _fold(nameOf(country.code, 'en')).contains(q) ||
        country.code.toLowerCase() == q;
  }

  static bool isKnown(String? code) => code != null && kCountryCodes.contains(code.toUpperCase());

  /// Lower case with the common Latin diacritics removed, for matching what people type.
  static String fold(String s) => _fold(s);

  static String _fold(String s) {
    const from = 'áàâäãåāăąçćčďéèêëēęěíìîïīłńňñóòôöõőøřśšșşťțúùûüűůýÿžźż';
    const plain = 'aaaaaaaaacccdeeeeeeeiiiiilnnnooooooorssssttuuuuuuyyzzz';
    final lower = s.toLowerCase();
    final buffer = StringBuffer();
    for (final rune in lower.runes) {
      final ch = String.fromCharCode(rune);
      final i = from.indexOf(ch);
      buffer.write(i >= 0 ? plain[i] : ch);
    }
    return buffer.toString();
  }
}
