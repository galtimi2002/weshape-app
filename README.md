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
- **Tabs: Map · Assessment · Saved assessments**: in the header, left of the
  language menu, in the thin search font with a line that slides under the
  active tab; on narrow screens in a strip under the header (icon + short name,
  icons only under 340 px). Assessment and Saved assessments are full pages
  (`lib/features/assessment/`) that fade and slide in over the map; the map stays
  alive underneath (`ResourceMap.active` turns its clicks off meanwhile).
  The assessment (`assessment_flow.dart`, answers in `home_answers.dart`): one
  question per screen, and which screens appear depends on the answers (the
  building questions only when heating is chosen, the bill questions only for
  mains electricity, gas only for piped gas, and so on), so the "Step n of N"
  count follows them. The order: who it is for (six cards, only "My home" open),
  where it is, what to power, the building (type, area, floors, people; when it
  was built; renovations for older ones; insulation; windows, with "Help me
  check" tips), how energy comes in today (several answers), power cuts, electricity used and paid in the last
  three full months (or a monthly average, with a note that months are more
  accurate; currency from the country, searchable, in `currencies.dart`), gas in
  m³ or kWh with a check for the wrong unit, other fuels, free space and its size, who owns it, upkeep,
  what matters most, follow-ups read from our maps (river within 500 m, wind at
  20 m from the 10 m and 50 m values, skipped below 3 m/s; animals and a brook
  only with a garden or land) and places to keep free (the roof shape, then a
  3D house on its plot that turns in quarter steps: roof sides and yard parts are
  tapped to keep them free, or, for the yard parts, marked as not there; left
  and right as seen from the street), and last, after a short "Just one more question",
  whether there is something new the map does not show yet: what it is, where
  (tapped on the same 3D house), and whether it could be used. The questions never name an energy type: the result
  says what suits the place. Answers are saved on the device
  (`shared_preferences`, key `assessment.home.v2`), so someone who leaves to find
  a bill continues where they stopped. The result is next, so "See my result"
  is shown but cannot be pressed yet. Saved assessments shows its empty state.
  What is not built yet (the other audiences, photos, drawing on the map, reading
  a bill) shows "Soon" and cannot be clicked.

## Home: resource map

The home screen is one full-screen map that opens on the country from the
person's profile. They can search an address or click anywhere, and a card
shows the resource there. **Solar**, **Wind**, **Hydro**, **Geothermal** and
**Biomass** work (the last three show as coming soon until the backend reports
their data is built).

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

Then check the texts:

```bash
python3 tool/check_translations.py      # or: ... de nl  for some languages
```

It reports placeholders that differ from English, texts left in English, a
mixed form of address (each language speaks one way: Sie in German, u in
Dutch, vous in French, siz in Turkish, tu in Romanian and Italian, te in
Hungarian ...), answer options written with a possessive ("On the roof", not
"On my roof"), and labels much longer than English. Hungarian is the reference
for meaning: where English and Hungarian differ, the other languages follow
the Hungarian.

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
- **Wind data: Global Wind Atlas** (DTU and the World Bank, CC BY 4.0),
  250 m for every country. Three layers: mean wind speed at 100 m, wind power
  density at 100 m, and wind speed by height (10, 50, 100, 150, 200 m). The
  card shows the speed-by-height profile instead of monthly bars. The world
  files (81 GB) are re-encoded to about 10 GB of cloud-optimised GeoTIFFs in a
  Cloudflare R2 bucket (weshape-wind); 150 m is worked out from 100 and 200 m
  (0.6 % mean error), the other heights are stored. Built by the backend's
  "Build wind map data" workflow.
- **Switching to wind plays a short breeze:** soft blurred gusts and a few
  leaves sweep across the map and a turbine spins up, then everything fades
  out after about 3 seconds (only when arriving at wind, not between wind
  layers; skipped when the system asks for reduced motion). Agreed on the
  sketch, keep it.
  - Inclined plane irradiation (kWh/m² per year, like GTI)
  - Annual PV production (kWh/kWp per year, like PVOUT)
  - Optimum tilt angle (degrees, like OPTA)
- **Google Solar API**: maybe later, only as a paid extra (free monthly quota,
  then paid; Romania coverage not confirmed).
- **Geothermal data**: three layers, as asked for: **Geothermal temperature**
  (annual mean ground temperature near the surface, SoilTemp, ~1 km),
  **Temperature at depth** (1, 2, 3 or 5 km, picked like the wind heights;
  estimated as ground temperature + heat flow ÷ 2.5 W/m·K × depth) and
  **Geothermal heat flow** (mW/m², from the Global Heat Flow Database 2024
  measurements, smoothed; empty where no measurement lies within 250 km).
  One orange–brick colour scale, the depth layer with its own range per depth.
  The card shows the three values and the temperature by depth as bars.
  Built by the backend's "Build geothermal map data" workflow.
- **Biomass data**: three layers, as asked for: **Biomass availability density**
  (t/ha per year here), **Biomass resource potential** (thousand t per year
  within a 25 km collection radius) and **Biomass energy potential** (GWh per
  year within 25 km). Crop residues from MapSPAM 2020 crop production
  (residue ratio per crop, 40 % taken, the rest stays on the field), forest
  residues from ESA CCI above-ground biomass. One green colour scale. The card
  shows the three values, crop and forest residues as two bars and roughly how
  many family homes that heat would warm for a year (15 MWh each). Built by the
  backend's "Build biomass map data" workflow.
- **The card follows the language switch**: "Selected point", the place name and
  a "no data" message are looked up again in the new language.

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
