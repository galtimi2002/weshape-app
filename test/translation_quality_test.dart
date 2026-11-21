// Checks every language's interface text for the kinds of mistakes that slipped in before:
// the wrong form of address (du instead of Sie in German), a word left in English, a missing
// or misspelt placeholder, a Latin letter hidden inside a Cyrillic word, broken month lists.
//
// The texts are read from the generated lib/core/i18n/strings/strings_<code>.dart files, so
// the test sees exactly what ships. Fix a finding in tool/translations.py, then run
// python3 tool/gen_strings.py.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:weshape_app/core/i18n/languages.dart';

/// key -> text for one language, read from its generated Dart file.
Map<String, String> _load(String code) {
  final file = File('lib/core/i18n/strings/strings_$code.dart');
  if (!file.existsSync()) throw StateError('missing ${file.path}');
  final line = RegExp(r"^  (\w+): '((?:[^'\\]|\\.)*)',$");
  final out = <String, String>{};
  for (final l in file.readAsLinesSync()) {
    final m = line.firstMatch(l);
    if (m == null) continue;
    out[m.group(1)!] = m.group(2)!.replaceAllMapped(RegExp(r'\\(.)'), (e) => e.group(1)!);
  }
  return out;
}

/// A regex whose word boundaries work for any script (Dart's \b only knows ASCII letters).
RegExp _words(String alternatives, {bool caseSensitive = true}) => RegExp(
      '(?<![\\p{L}\\p{M}])($alternatives)(?![\\p{L}\\p{M}])',
      unicode: true,
      caseSensitive: caseSensitive,
    );

/// How the app addresses the user in each language, and the words that would give the
/// other form away. Only languages where the two forms use clearly different words.
final Map<String, (String, RegExp)> _otherForm = {
  'de': ('Sie', _words('du|dich|dir|dein|deine|deinen|deinem|deiner|deines|Hilf|Tippe|Wähle|Gib|Sieh|Klicke|Melde|Prüfe|Versuche es|Erstelle|Warte|Verwende|Nutze')),
  'nl': ('u', _words('je|jij|jou|jouw')),
  'fr': ('vous', _words('tu|ton|ta|tes|toi|te')),
  'es': ('tú', _words('usted|ustedes')),
  'it': ('tu', _words('Lei|Suo|Sua|Suoi|Sue')),
  'pt': ('você', _words('tu|teu|tua|teus|tuas')),
  'ro': ('tu', _words('dumneavoastră|dvs')),
  'pl': ('ty', _words('Pan|Pani|Państwo|Pana')),
  'hr': ('vi', _words('ti|tvoj|tvoja|tvoje|tvoju|tebi|tebe')),
  'ru': ('вы', _words('ты|твой|твоя|твоё|твои|тебя|тебе')),
  'tr': ('siz', _words('sen|senin|sana|seni|hesabın|şifreni|ülkeni|bağlantını')),
  'cs': ('vy', _words('ty|tvůj|tvoje|tvého|tobě|tebe')),
  'sk': ('vy', _words('ty|tvoj|tvoje|tebe|tebou')),
  'sl': ('vi', _words('ti|tvoj|tvoja|tvoje|tebe|tebi')),
  'bg': ('вие', _words('ти|твой|твоя|твоето|теб')),
  'uk': ('ви', _words('ти|твій|твоя|твоє|тебе|тобі')),
  'be': ('вы', _words('ты|твой|твая|цябе|табе')),
  'sr': ('ви', _words('ти|твој|твоја|тебе|теби')),
  'mk': ('вие', _words('ти|твој|твоја|тебе')),
  'bs': ('vi', _words('ti|tvoj|tvoja|tvoje|tebe|tebi')),
  'lt': ('jūs', _words('tu|tavo|tave|tau')),
  'lv': ('jūs', _words('tu|tavs|tava|tevi|tev')),
  'et': ('sina', _words('Teie|Teid|Teil')),
  'nb': ('du', _words('Dem|Deres')),
  'ca': ('tu', _words('vostè|vostès')),
  'gl': ('ti', _words('vostede|vostedes')),
  'lb': ('du', _words('Dir|Iech|Ären')),
  'sq': ('ti', _words('Ju|juaj')),
};

const _cyrillic = {'ru', 'uk', 'bg', 'sr', 'mk', 'be'};

/// Languages written in their own script: Latin letters may appear only as units and names.
const _ownScript = {
  'el', 'ar', 'fa', 'ur', 'hi', 'ne', 'bn', 'pa', 'th', 'my', 'am', 'zh', 'ja', 'ko', ..._cyrillic,
};

/// Latin words allowed in other scripts: units, the brand, abbreviations.
const _latinOk = {
  'Google', 'kWh', 'kWp', 'kW', 'km', 'm', 'W', 'GWh', 'mW', 'K', 'L', 'kg', 'cm', 's', 'ha', 't',
  'C', 'PV', 'k', 'LPG', 'email', 'Email',
  // US units in the unit picker and the note on cords of firewood.
  'ft', 'mi', 'F', 'cord',
};

final _nonLatinScripts = RegExp(
    '[Ͱ-ϿЀ-ӿ֐-ۿऀ-෿฀-๿က-႟'
    'ሀ-᎟぀-ヿ一-鿿가-힯]');

final _placeholder = RegExp(r'\{\w+\}');

List<String> _sortedPlaceholders(String s) =>
    _placeholder.allMatches(s).map((m) => m.group(0)!).toList()..sort();

void main() {
  final codes = AppLanguages.all.map((l) => l.code).toList();
  final en = _load('en');
  final all = {for (final c in codes) c: _load(c)};

  test('the English file was read', () {
    expect(en.length, greaterThan(400));
    expect(en['signIn'], 'Sign in');
  });

  test('every language has exactly the English keys', () {
    for (final c in codes) {
      expect(all[c]!.keys.toSet(), en.keys.toSet(), reason: c);
    }
  });

  test('no empty texts and no stray spaces', () {
    final problems = <String>[];
    all.forEach((c, t) => t.forEach((k, v) {
          if (v.trim().isEmpty) problems.add('$c.$k is empty');
          if (v != v.trim()) problems.add('$c.$k has a leading or trailing space');
          if (v.contains('  ')) problems.add('$c.$k has a double space');
        }));
    expect(problems, isEmpty);
  });

  test('placeholders match English, and braces are balanced', () {
    final problems = <String>[];
    all.forEach((c, t) => t.forEach((k, v) {
          final want = _sortedPlaceholders(en[k]!);
          final got = _sortedPlaceholders(v);
          if (want.join() != got.join()) problems.add('$c.$k: $got, English has $want');
          final rest = v.replaceAll(_placeholder, '');
          if (rest.contains('{') || rest.contains('}')) problems.add('$c.$k: stray brace in "$v"');
        }));
    expect(problems, isEmpty);
  });

  test('no sentence is left in English', () {
    final problems = <String>[];
    all.forEach((c, t) {
      if (c == 'en') return;
      t.forEach((k, v) {
        final e = en[k]!;
        if (v == e && e.length > 14 && e.contains(' ')) problems.add('$c.$k: "$v"');
      });
    });
    expect(problems, isEmpty);
  });

  test('twelve distinct month names in every language', () {
    for (final c in codes) {
      final months = all[c]!['monthNames']!.split(',');
      expect(months, hasLength(12), reason: c);
      expect(months.every((m) => m.trim().isNotEmpty && m == m.trim()), isTrue, reason: c);
      expect(months.toSet(), hasLength(12), reason: '$c has a month twice');
    }
  });

  test('each language addresses the user one way only (e.g. Sie in German, never du)', () {
    final problems = <String>[];
    _otherForm.forEach((c, rule) {
      final (form, other) = rule;
      all[c]!.forEach((k, v) {
        final m = other.firstMatch(v);
        if (m != null) problems.add('$c.$k uses "${m.group(0)}" ($form expected): "$v"');
      });
    });
    expect(problems, isEmpty);
  });

  test('German speaks formally: the polite Sie and Ihr are capitalised', () {
    // "Wählen sie …" or "Ihrem Konto" written in lower case would read as "they / their".
    final lowSie = RegExp(r'(^|[.!?:]\s+)\p{Lu}\p{L}*en sie(?![\p{L}])', unicode: true);
    final lowIhr = RegExp(
        r'(?<![\p{L}])ihr(e|em|en|er|es)? (Konto|Passwort|Adresse|E-Mail|Haus|Dach|Land|Antworten|Profil|Verbindung|Posteingang|Ort|Grundstück|Rechnung)',
        unicode: true);
    final problems = <String>[];
    all['de']!.forEach((k, v) {
      if (lowSie.hasMatch(v) || lowIhr.hasMatch(v)) problems.add('de.$k: "$v"');
    });
    expect(problems, isEmpty);
  });

  test('no word mixes Latin and Cyrillic letters (they look alike but are different)', () {
    final mixed = RegExp(r'[\p{L}]*(?:[a-zA-Z][Ѐ-ӿ]|[Ѐ-ӿ][a-zA-Z])[\p{L}]*', unicode: true);
    final problems = <String>[];
    all.forEach((c, t) => t.forEach((k, v) {
          final m = mixed.firstMatch(v);
          if (m != null) problems.add('$c.$k: "${m.group(0)}"');
        }));
    expect(problems, isEmpty);
  });

  test('each language stays in its own script', () {
    final latinWord = RegExp('[A-Za-z]+');
    final problems = <String>[];
    all.forEach((c, t) => t.forEach((k, v) {
          final text = v.replaceAll(_placeholder, '');
          if (_ownScript.contains(c)) {
            final stray = latinWord.allMatches(text).map((m) => m.group(0)!).where((w) => !_latinOk.contains(w));
            if (stray.isNotEmpty) problems.add('$c.$k: Latin "${stray.join(' ')}"');
          } else if (_nonLatinScripts.hasMatch(text)) {
            problems.add('$c.$k: letters from another script in "$v"');
          }
        }));
    expect(problems, isEmpty);
  });

  test('units from English survive the translation', () {
    const units = {'m²': 'м²', 'm³': 'м³', '°C': '°C', 'm/s': 'м/с', 'kWh': 'кВт·'};
    // Firewood measures go by their local names, which say "cubic metre" in their own words
    // (Raummeter, metru ster, stère, складометр).
    const localNames = {'woodUnitStacked', 'woodUnitLoose', 'woodUnitSolid'};
    final problems = <String>[];
    // Languages in their own script may write units their way (м³, 立方米, م³); Cyrillic
    // ones are still checked, with the Cyrillic spelling allowed.
    all.forEach((c, t) {
      if (_ownScript.contains(c) && !_cyrillic.contains(c)) return;
      t.forEach((k, v) {
        if (localNames.contains(k)) return;
        final e = en[k]!;
        units.forEach((latin, cyr) {
          if (e.contains(latin) && !v.contains(latin) && !v.contains(cyr)) {
            problems.add('$c.$k lost "$latin": "$v"');
          }
        });
      });
    });
    expect(problems, isEmpty);
  });

  test('French puts a (narrow) non-breaking space before ? ! : ;', () {
    final bad = RegExp(r'\S[?!:;](\s|$)');
    final problems = <String>[];
    all['fr']!.forEach((k, v) {
      if (bad.hasMatch(v) && !v.contains('://')) problems.add('fr.$k: "$v"');
    });
    expect(problems, isEmpty);
  });

  // Texts a person has reviewed. If one changes by accident, this says so; if it changes on
  // purpose, update it here too.
  group('reviewed texts stay as reviewed', () {
    const reviewed = {
      'de': {
        'signIn': 'Anmelden',
        'signOut': 'Abmelden',
        'createAccount': 'Konto erstellen',
        'forgotPassword': 'Passwort vergessen?',
        'rememberMe': 'Angemeldet bleiben',
        'backToMap': 'Zurück zur Karte',
        'switchToDark': 'Zum dunklen Modus wechseln',
        'signInSubtitle': 'Melden Sie sich bei Ihrem Konto an',
        'placeHint': 'Geben Sie die Adresse ein oder wählen Sie einen Punkt auf der Karte.',
        'cutsTitle': 'Wie oft fällt bei Ihnen der Strom aus?',
        'srcHint': 'Wählen Sie nur, was Sie ersetzen möchten. Was bleiben kann, wie es ist, lassen Sie weg.',
        'stepNumber': 'Schritt {n}',
      },
      'hu': {
        'signIn': 'Bejelentkezés',
        'signOut': 'Kijelentkezés',
        'createAccount': 'Regisztráció',
        'backToMap': 'Vissza a térképhez',
        'switchToDark': 'Váltás sötét módra',
        'cutsTitle': 'Milyen gyakran megy el az áram?',
        'srcHint': 'Csak azt válaszd ki, amit le szeretnél váltani. Ami maradhat úgy, ahogy van, azt hagyd ki.',
        'stepNumber': '{n}. lépés',
      },
    };
    reviewed.forEach((c, texts) {
      test(c, () {
        texts.forEach((k, v) => expect(all[c]![k], v, reason: '$c.$k'));
      });
    });

    test('hu: replacing something is "lecserél / leváltani", never "kiváltani"', () {
      final wrong = _words('ki szeretnél váltani|kiváltani|kiváltod', caseSensitive: false);
      all['hu']!.forEach((k, v) => expect(wrong.hasMatch(v), isFalse, reason: 'hu.$k: "$v"'));
    });
  });
}
