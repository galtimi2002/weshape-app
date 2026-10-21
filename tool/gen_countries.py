#!/usr/bin/env python3
"""Regenerates lib/core/i18n/country_names.g.dart from the Unicode CLDR.

    pip install babel
    python3 tool/gen_countries.py

The country list is Java's Locale.getISOCountries(), the same list the backend
validates against. It is stored in tool/iso_countries.txt so this script does
not need a JDK.
"""
import pathlib

from babel import Locale

ROOT = pathlib.Path(__file__).resolve().parent.parent
LANGS = ["en", "hu", "ro", "de", "fr", "es", "it", "pt", "nl", "pl", "hr", "fi", "ru", "tr", "zh"]
ISO = (ROOT / "tool" / "iso_countries.txt").read_text().strip().split(",")


def esc(s: str) -> str:
    return s.replace("\\", "\\\\").replace("'", "\\'").replace("$", "\\$")


english = Locale("en").territories
out = [
    "// GENERATED from the Unicode CLDR (via Babel) by tool/gen_countries.py.",
    "// Do not edit by hand; re-run the script instead.",
    "//",
    "// Country names in every app language, so the country picker reads naturally",
    "// whatever language the interface is in. The code list matches Java's",
    "// Locale.getISOCountries(), which is what the backend validates against.",
    "",
    "// ignore_for_file: lines_longer_than_80_chars",
    "",
    "const List<String> kCountryCodes = <String>[",
    *[f"  '{c}'," for c in ISO],
    "];",
    "",
    "const Map<String, Map<String, String>> kCountryNames = <String, Map<String, String>>{",
]
for lang in LANGS:
    names = Locale.parse(lang).territories
    out.append(f"  '{lang}': <String, String>{{")
    out += [f"    '{c}': '{esc(names.get(c) or english.get(c) or c)}'," for c in ISO]
    out.append("  },")
out += ["};", ""]

(ROOT / "lib" / "core" / "i18n" / "country_names.g.dart").write_text("\n".join(out), encoding="utf-8")
print("wrote", len(ISO), "countries x", len(LANGS), "languages")
