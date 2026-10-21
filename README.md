# weshape-app

Flutter client for **WeShape Energy**: web first, Android and iOS from the
same code.

## First run

Platform folders are generated, not committed:

```bash
./tool/bootstrap.sh
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080
```

That is **demo mode**: sign-in is simulated on the device and the backend must
run with `WESHAPE_AUTH_MODE=dev`. Any email with an 8+ character password works.

For real accounts:

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=<firebase-project-id>   # rewrites lib/firebase_options.dart
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080 --dart-define=AUTH_MODE=firebase
```

## What is in it

- **Login**: email + password, "remember me", forgotten password (the reset
  email arrives in the current language), Google.
- **Registration**: first name, last name, email, country, language, password.
- **One more step**: after a first Google sign-in, asks for what Google does not
  give (country, and names if missing).
- **Home**: header with language, sun/moon theme switch, log out and the
  account card with the personal code. The content area is empty for now.

## Language and theme rules

- A first visit is in **English**.
- At registration, picking a country switches to that country's language,
  until the person picks a language themselves; their pick then stays.
- Signed out, the choice is remembered on the device.
- Signed in, every change is saved to the profile, so it follows the person to
  any device and comes back at the next sign-in.
- Theme starts as "follow the system"; the switch pins light or dark.

19 languages: English, Magyar, Română, Deutsch, Français, Español, Italiano,
Português, Nederlands, Polski, Hrvatski, Suomi, Svenska, Dansk, Ελληνικά,
Русский, Türkçe, 中文 (Mandarin, simplified), 日本語.

### Changing texts

Texts live in `tool/translations.py`. After editing:

```bash
python3 tool/gen_strings.py
```

The generator refuses to write anything if a language is missing a string. A
new string also has to be added to `lib/core/i18n/app_strings.dart`; the
compiler then insists on it in every language.

Country names come from the Unicode CLDR (`tool/gen_countries.py`), so the
country list reads naturally in each language.

## Design

Colors are in `lib/core/theme/weshape_palette.dart`, straight from the
approved sketch: navy on light, soft blue on dark, green only in the logo and
the online dot, errors in muted terracotta. Font: Plus Jakarta Sans.

## Deploy (Render static site)

`render.yaml` builds with `tool/render_build.sh`, which downloads Flutter on
Render, runs `flutter create`, applies the branding (`tool/web_branding.sh`)
and builds. Set `API_BASE_URL` and `AUTH_MODE` on the service.

To change the browser icon later, replace the files in `assets/brand/web/`
and raise `ICON_VERSION` in `tool/web_branding.sh`, otherwise browsers keep
showing the old one from cache.

## Tests

```bash
flutter test
```
