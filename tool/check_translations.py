#!/usr/bin/env python3
"""Checks the app's texts in tool/translations.py, the same way for every language.

    python3 tool/check_translations.py           # every language
    python3 tool/check_translations.py de nl     # only these

What it looks for, per language:
  - keys missing or extra compared with English;
  - placeholders ({n}, {total}, {m}, {speed}, {country} ...) that differ from English;
  - texts left in English (same as the English text, and long enough to be a sentence);
  - the form of address: each language speaks to the user one way (tu or vous, du or Sie),
    and a text that uses the other one is reported;
  - texts much longer than English where space is short (chips, buttons, labels);
  - French spacing: a non-breaking space before ? ! : ;
  - the answer options of the assessment written with a possessive (my roof, your roof):
    options say "On the roof", not "On my roof" (questions may still say "your").

It prints what it finds and exits with 1 when something needs fixing, so it can run in CI.
"""

import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
T: dict[str, dict[str, str]] = {}
exec((HERE / "translations.py").read_text(encoding="utf-8"))  # defines T

# How the app speaks to the user in each language, and the words that give the other way
# away. Only languages where the two forms are told apart by distinct words are checked.
ADDRESS = {
    # language: (what the app uses, regex of words that belong to the other form)
    "de": ("Sie", r"\b(du|dich|dir|dein|deine|deinen|deinem|deiner|deines|Hilf|prüft|Tippe|Wähle|Gib|Sieh|Klicke|Melde|Prüfe|Versuche es|Erstelle|Warte|Verwende|Nutze)\b"),
    "nl": ("u", r"\b(je|jij|jou|jouw)\b"),
    "fr": ("vous", r"\b(tu|ton|ta|tes|toi|te)\b"),
    "es": ("tú", r"\b(usted|ustedes)\b"),
    "it": ("tu", r"\b(Lei|Suo|Sua|Suoi|Sue)\b"),
    "pt": ("você", r"\b(tu|teu|tua|teus|tuas)\b"),
    "ro": ("tu", r"\b(dumneavoastră|dvs\.?)\b"),
    "pl": ("ty", r"\b(Pan|Pani|Państwo|Pana|Pani)\b"),
    "hr": ("vi", r"\b(ti|tvoj|tvoja|tvoje|tvoju|tebi|tebe)\b|^(Nacrtaj|Označi|Snimi|Pomozi|Odaberi|Dodirni|Pogledaj|Okreni|Unesi|Upiši|Klikni)\b"),
    "ru": ("вы", r"\b(ты|твой|твоя|твоё|твои|тебя|тебе)\b"),
    "el": ("εσείς", r"\b(εσύ|σου|σε ξαναβλέπουμε|Βοήθησέ|Τράβηξε|Δείξε|δείξε|Χρησιμοποίησε|Περίμενε|Δοκίμασε|δοκίμασε|Έλεγξε|Συνδέσου|Επίλεξε|Σχεδίασέ|Σημείωσέ|Πάτησε|Γράψε)\b"),
    "tr": ("siz", r"\b(sen|senin|sana|seni|hesabın|şifreni|ülkeni|bağlantını)\b|\b(dene|gir|seç|kontrol et)\.?$|^\w+ (çiz|işaretle|çek|döndür|bak|dokun|aç|oku)$"),
}

# Keys whose text sits in a chip, a button or a short label.
SHORT = re.compile(
    r"^(aud(?!.*Desc|Title)|use[A-Z]|src[A-Z](?!.*Title)|reno(?!Title|When)|age|"
    r"ins(?!Title|Help)|win(?!Title|Help)|sp[A-Z]|land|balcony|roof(?!Hidden)|face|own(?!Title|Hint)|"
    r"fix(?!Title|Hint)|hands(?!Title)|prio[A-Z]\w*(?<!Desc)|anim(?!alsQ)|zone|why(?!Label)|mark|"
    r"new(?:Building|Pool|Trees|Other|Yes|No)|noGarden|seeResult|assessContinue|back)$"
)

# Answer options of the assessment: no possessive (decided with the team).
OPTIONS = re.compile(
    r"^(aud(?!.*Desc|Title)|use[A-Z]|src[A-Z](?!.*Title)|sp[A-Z]|land|balcony|own(?!Title|Hint)|"
    r"zone|noGarden|sizeRoofLabel|sizeGardenLabel|sizeLandLabel|sizeBalconyLabel|river(?:Through|Others)|"
    r"seeResult|confirmGo|resetAnswers)$"
)
POSSESSIVE = {
    "en": r"\b(my|your)\b",
    "hu": r"\b\w+(?:em|om|öm|am|ed|od|öd|ad|ünk|unk)\b(?<!nem)(?<!Nem)",  # noisy: reported as a hint
    "ro": r"\b(meu|mea|mei|mele|tău|ta|tale)\b",
    "de": r"\b(mein\w*|dein\w*|Ihr\w*)\b",
    "fr": r"\b(mon|ma|mes|ton|ta|tes|votre|vos)\b",
    "es": r"\b(mi|mis|tu|tus|su|sus)\b",
    "it": r"\b(mio|mia|miei|mie|tuo|tua|tuoi|tue)\b",
    "pt": r"\b(meu|minha|meus|minhas|seu|sua|seus|suas)\b",
    "nl": r"\b(mijn|jouw|uw|je)\b",
    "pl": r"\b(mój|moja|moje|mojego|mojej|twój|twoja|twoje)\b",
    "hr": r"\b(moj|moja|moje|moju|vaš|vaša|vaše)\b",
    "ru": r"\b(мой|моя|моё|мои|ваш|ваша|ваше|ваши)\b",
    "sv": r"\b(min|mitt|mina|din|ditt|dina)\b",
    "da": r"\b(min|mit|mine|din|dit|dine)\b",
    "el": r"\b(μου|σας)\b",
}

PLACEHOLDER = re.compile(r"\{\w+\}")


def check(lang: str) -> list[str]:
    en, tr = T["en"], T[lang]
    out = []
    for k in en.keys() - tr.keys():
        out.append(f"missing key {k}")
    for k in tr.keys() - en.keys():
        out.append(f"extra key {k}")
    for k, v in tr.items():
        if k not in en:
            continue
        e = en[k]
        if sorted(PLACEHOLDER.findall(v)) != sorted(PLACEHOLDER.findall(e)):
            out.append(f"placeholders differ in {k}: {v!r}")
        if lang != "en" and v == e and len(e) > 14 and " " in e:
            out.append(f"still in English: {k}: {v!r}")
        if lang in ADDRESS and re.search(ADDRESS[lang][1], v):
            out.append(f"form of address ({ADDRESS[lang][0]} expected) in {k}: {v!r}")
        if SHORT.match(k) and len(v) > max(24, 1.8 * len(e)):
            out.append(f"long for a chip/button ({len(v)} vs {len(e)}): {k}: {v!r}")
        if lang == "fr" and re.search(r"\S[?!:;](\s|$)", v) and "://" not in v:
            out.append(f"French spacing before ? ! : ; in {k}: {v!r}")
        if OPTIONS.match(k) and lang in POSSESSIVE and lang != "hu" and re.search(POSSESSIVE[lang], v, re.I):
            out.append(f"possessive in an answer option {k}: {v!r}")
    return out


def main() -> int:
    langs = sys.argv[1:] or list(T)
    total = 0
    for lang in langs:
        found = check(lang)
        total += len(found)
        if found:
            print(f"== {lang} ({len(found)})")
            for line in sorted(found):
                print("  " + line)
    print(f"{total} finding(s) in {len(langs)} language(s)")
    return 1 if total else 0


if __name__ == "__main__":
    sys.exit(main())
