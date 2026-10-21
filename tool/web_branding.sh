#!/usr/bin/env bash
# Stamps WeShape Energy's branding onto the generated web/ folder.
#
# web/ is not checked in: `flutter create` regenerates it with Flutter's own
# icons. The real icons live in assets/brand/web/ and are copied over here.
#
# The icon links get a ?v=N suffix. Browsers keep favicons in a separate cache
# that a hard refresh does not clear, so a new URL is the only reliable way to
# make every earlier visitor fetch a changed icon. Bump ICON_VERSION when the
# icon changes.
#
# Run after `flutter create` and before `flutter build web`:
#   ./tool/web_branding.sh
set -euo pipefail

cd "$(dirname "$0")/.."

ICON_VERSION="${ICON_VERSION:-1}"
SRC="assets/brand/web"

if [ ! -d web ]; then
  echo "web/ does not exist yet. Run 'flutter create --platforms=web .' first." >&2
  exit 1
fi

mkdir -p web/icons
cp "$SRC/favicon.png"           web/favicon.png
cp "$SRC/favicon.ico"           web/favicon.ico
cp "$SRC/Icon-192.png"          web/icons/Icon-192.png
cp "$SRC/Icon-512.png"          web/icons/Icon-512.png
cp "$SRC/Icon-maskable-192.png" web/icons/Icon-maskable-192.png
cp "$SRC/Icon-maskable-512.png" web/icons/Icon-maskable-512.png
cp "$SRC/apple-touch-icon.png"  web/icons/apple-touch-icon.png

ICON_VERSION="$ICON_VERSION" python3 - <<'PY'
import json
import os
import pathlib
import re

version = os.environ["ICON_VERSION"]

manifest_path = pathlib.Path("web/manifest.json")
manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
manifest["name"] = "WeShape Energy"
manifest["short_name"] = "WeShape"
manifest["description"] = "We care about the future of green energy."
manifest["background_color"] = "#F5F7FA"
manifest["theme_color"] = "#1E3A6E"
for icon in manifest.get("icons", []):
    icon["src"] = re.sub(r"\?v=\d+$", "", icon["src"]) + f"?v={version}"
manifest_path.write_text(json.dumps(manifest, indent=4) + "\n", encoding="utf-8")

index_path = pathlib.Path("web/index.html")
html = index_path.read_text(encoding="utf-8")

# Matched by rel rather than by exact text: Flutter has rewritten this
# template more than once, and an exact match would silently stop applying.
html = re.sub(r'\s*<link rel="(?:shortcut icon|icon|apple-touch-icon)"[^>]*>', "", html)
icons = (
    f'\n  <link rel="icon" type="image/png" href="favicon.png?v={version}"/>'
    f'\n  <link rel="shortcut icon" href="favicon.ico?v={version}"/>'
    f'\n  <link rel="apple-touch-icon" href="icons/apple-touch-icon.png?v={version}">'
)
html = html.replace("</head>", icons + "\n</head>", 1)

html = re.sub(r"<title>.*?</title>", "<title>WeShape Energy</title>", html, flags=re.S)
html = re.sub(
    r'<meta name="description" content="[^"]*">',
    '<meta name="description" content="We care about the future of green energy.">',
    html,
)
html = re.sub(r'<meta name="apple-mobile-web-app-title" content="[^"]*">',
              '<meta name="apple-mobile-web-app-title" content="WeShape">', html)
if 'name="theme-color"' not in html:
    html = html.replace("</head>", '  <meta name="theme-color" content="#1E3A6E">\n</head>', 1)

index_path.write_text(html, encoding="utf-8")
PY

echo "==> WeShape Energy web branding applied (icon version $ICON_VERSION)"
