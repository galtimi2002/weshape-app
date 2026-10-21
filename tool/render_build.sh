#!/usr/bin/env bash
# Build command for the Render static site. Render has no Flutter, so this
# fetches the stable SDK (cached between builds), then builds the web app.
#
# Uses the service's environment variables:
#   API_BASE_URL  e.g. https://weshape-backend.onrender.com
#   AUTH_MODE     firebase (or demo)
set -euo pipefail

cd "$(dirname "$0")/.."

FLUTTER_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/flutter"
if [ ! -x "$FLUTTER_DIR/bin/flutter" ]; then
  git clone --depth 1 --branch stable https://github.com/flutter/flutter.git "$FLUTTER_DIR"
fi
export PATH="$FLUTTER_DIR/bin:$PATH"

flutter --version
flutter config --no-analytics --enable-web >/dev/null
flutter create --project-name weshape_app --org energy.weshape --platforms=web .
bash tool/web_branding.sh
flutter pub get
flutter build web --release \
  --dart-define=API_BASE_URL="${API_BASE_URL:?Set API_BASE_URL on the Render service}" \
  --dart-define=AUTH_MODE="${AUTH_MODE:-firebase}"
