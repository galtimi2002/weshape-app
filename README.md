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
  account card, and under it the resource map (below).

## Home: resource map

The home screen is one full-screen map that opens on the country from the
person's profile. They can search an address or click anywhere, and a card
shows the solar resource there. Only **Solar** works for now; Wind, Hydro,
Geothermal and Biomass are shown as coming soon.

Solar has three layers, switchable under the resource buttons and from the
card: irradiation on an optimally inclined plane (GTI, kWh/m²), annual PV
production (PVOUT, kWh/kWp) and the optimum tilt angle (OPTA, degrees).

How it is built (`lib/features/home/map/`):

- **Map**: MapLibre GL JS with the OpenFreeMap "positron" base map, recoloured
  for dark mode, place names in the app language where OpenStreetMap has them.
  It runs in the page: `assets/map/weshape_map.js` loads MapLibre from unpkg
  and `map_bridge_web.dart` talks to it. Flutter draws the search, card and
  dock on top and tells the map where they are, so clicks on them stay off the map.
- **Solar values and layer pictures**: from the backend
  (`/api/v1/solar/point`, `/api/v1/solar/layers/{gti,pvout,opta}.png`). Today
  these are example values; the backend will switch to Global Solar Atlas and
  PVGIS without the app changing.
- **Address search and place names**: Photon (photon.komoot.io, OpenStreetMap
  data), results from the person's country first. The public Photon server is
  fine for development; pick a hosted geocoder before launch (only
  `geocoder.dart` changes).

To try it locally, run the backend and then:

```bash
flutter pub get
flutter run -d edge --dart-define=API_BASE_URL=http://localhost:8080
```

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

Agreed while designing the home page (resource map). Solar is built; the other resources come later.

- **Map library: MapLibre** (free, open source). We style the base map
  ourselves to match the app: muted grey base, our own colored resource layer
  on top, light and dark theme. Not Google Maps.
- **Solar data: PVGIS** (European Commission JRC, free, no key), for both
  the map and the card. The map layers come from a PVGIS grid built once
  (0.5° in Europe, 2° elsewhere, see the backend README); the card asks
  PVGIS live for the exact point. Global Solar Atlas was considered for the
  map, but its world files are 3–4 GB per layer, and one source keeps the
  map and the card consistent.
  - Inclined plane irradiation (kWh/m² per year, like GTI)
  - Annual PV production (kWh/kWp per year, like PVOUT)
  - Optimum tilt angle (degrees, like OPTA)
- **Google Solar API**: maybe later, only as a paid extra (free monthly quota,
  then paid; Romania coverage not confirmed).
- Wind, hydro, geothermal and biomass need their own data sources (e.g.
  Global Wind Atlas for wind); still to choose.

## Before launch (to do once the company exists)

- **Privacy policy page** at `https://weshapeenergy.com/privacy`: who runs the
  service (company name, address), contact email for data requests, what is
  stored (name, email, country, language, theme), where (Firebase / Google,
  Neon and Render in Frankfurt), how to ask for deletion. Mention that
  searched addresses go to the geocoder and clicked points to PVGIS. Have it
  checked for GDPR.
- **Terms of service** page, same place. It must include a **data
  disclaimer**: the solar figures are estimates for orientation, not a
  guaranteed yield. PVGIS's own usage conditions say the European Commission
  is not responsible for how its data is used, so ours should say the same.
- **Legal check of data sources and attribution** (have a lawyer look at it
  together with the terms):
  - PVGIS: free, no restrictions on use; they ask to be credited as
    "Photovoltaic Geographical Information System (PVGIS), European
    Commission Joint Research Centre", with a link to its home page. Done on
    the map (bottom left) and on the card. Conditions:
    https://joint-research-centre.ec.europa.eu/photovoltaic-geographical-information-system-pvgis/general-information/usage-conditions-data-protection_en
  - Base map: OpenFreeMap, OpenMapTiles, OpenStreetMap (ODbL). Credited by
    the map automatically; keep that line visible.
  - Address search: Photon (OpenStreetMap data). The public server is for
    testing only: **choose a production geocoder** (hosted plan or our own
    Photon) and check its terms, then change `geocoder.dart`.
- **Google sign-in branding** (Google Cloud → Google Auth Platform → Branding):
  app name "WeShape Energy", the 120×120 logo, home page, privacy policy link,
  then submit for brand verification so Google shows the name and logo.
- **GitHub, for the monthly solar data check** (backend repo):
  Settings → Actions → General → "Allow GitHub Actions to create and approve
  pull requests"; and in your account's notification settings, the
  notification email gl.tmea90@gmail.com.
- **Remove the `?maptest=1` shortcut** in `lib/app.dart` (debug builds only,
  but it is not needed any more).
