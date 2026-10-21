#!/usr/bin/env bash
# Generates the platform folders (android/, ios/, web/, ...) which are not
# checked in, brands the web build, fetches packages and runs the tests.
#
# Run once after cloning:
#   ./tool/bootstrap.sh
set -euo pipefail

cd "$(dirname "$0")/.."

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter is not on PATH. Install Flutter 3.29 or newer: https://docs.flutter.dev/get-started/install"
  exit 1
fi

flutter --version
flutter create --project-name weshape_app --org energy.weshape --platforms=android,ios,web,windows,macos .
bash tool/web_branding.sh
flutter pub get
flutter test

cat <<'MSG'

Done.

Demo mode against a local backend (WESHAPE_AUTH_MODE=dev):
  flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080

Real Firebase sign-in:
  flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080 --dart-define=AUTH_MODE=firebase
MSG
