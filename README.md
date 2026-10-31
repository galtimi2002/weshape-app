# weshape-app

Flutter client for **WeShape Energy**: web first, Android and iOS from the
same code.

## First run

Platform folders are generated, not committed:

```bash
./tool/bootstrap.sh
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080
```

Sign-in is real: Firebase Authentication, project `weshape-energy`
(email + password and Google). The backend must run with
`WESHAPE_AUTH_MODE=firebase` and the project's service account.

To try things without Firebase, add `--dart-define=AUTH_MODE=demo` and run the
backend with `WESHAPE_AUTH_MODE=dev`: sign-in is then simulated on the device,
and any email with an 8+ character password works.

Only the web app is registered in Firebase so far. For Android or iOS, register
them in the console and run `flutterfire configure`.

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

25 languages: English, Magyar, Română, Deutsch, Français, Español, Italiano,
Português, Nederlands, Polski, Hrvatski, Suomi, Svenska, Dansk, Ελληνικά,
Русский, Türkçe, 中文 (Mandarin, simplified), 日本語, 한국어, हिन्दी, বাংলা,
Bahasa Indonesia, Tiếng Việt, العربية (right to left).

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

## Map and data decisions

Agreed while sketching the home page (resource map); not built yet.

- **Map library: MapLibre** (free, open source). We style the base map
  ourselves to match the app: muted grey base, our own colored resource layer
  on top, light and dark theme. Not Google Maps.
- **Solar map layers: Global Solar Atlas** GIS data (World Bank / Solargis,
  CC BY 4.0, free; credit "Global Solar Atlas / Solargis" on the map):
  - Inclined plane irradiation: GTI, kWh/m² per year (~250 m)
  - Annual PV production: PVOUT, kWh/kWp per year (~1 km)
  - Optimum tilt angle: OPTA, degrees (~4 km)

  Prepared once into map tiles and served from our own server.
- **Values for an address and the monthly breakdown: PVGIS** (EU JRC, free,
  no API key, max 30 requests/s). Called from our backend, since PVGIS does not
  allow calls straight from the browser.
- **Google Solar API**: maybe later, only as a paid extra (free monthly quota,
  then paid; Romania coverage not confirmed).
- Wind, hydro, geothermal and biomass need their own data sources (e.g.
  Global Wind Atlas for wind); still to choose.

## Before launch (to do once the company exists)

- **Privacy policy page** at `https://weshapeenergy.com/privacy`: who runs the
  service (company name, address), contact email for data requests, what is
  stored (name, email, country, language, theme), where (Firebase / Google,
  Neon and Render in Frankfurt), how to ask for deletion. Have it checked for
  GDPR.
- **Terms of service** page, same place.
- **Google sign-in branding** (Google Cloud → Google Auth Platform → Branding):
  app name "WeShape Energy", the 120×120 logo, home page, privacy policy link,
  then submit for brand verification so Google shows the name and logo.
