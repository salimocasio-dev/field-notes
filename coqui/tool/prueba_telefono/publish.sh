#!/usr/bin/env bash
# Build the phone test page and copy it to prueba/ at the repo root (served by GitHub Pages at
# https://salimocasio-dev.github.io/field-notes/prueba/). Run from anywhere.
#
# Left out of prueba/: .last_build_id (Jekyll drops dot files anyway), flutter_service_worker.js (no service
# worker: web/flutter_bootstrap.js never registers one), debug symbols and source maps, and the CanvasKit
# builds a dart2js + CanvasKit app never loads (skwasm, wimp and webparagraph are for wasm builds or an
# opt-in flag). The two it does load stay: canvaskit/ (Safari, Firefox) and canvaskit/chromium/ (Chrome).
set -euo pipefail
app="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$app/../../.." && pwd)"
cd "$app"
flutter build web --release --base-href /field-notes/prueba/ --no-web-resources-cdn
rm -rf "$root/prueba"
mkdir -p "$root/prueba"
cp -R build/web/. "$root/prueba/"
cd "$root/prueba"
rm -f .last_build_id flutter_service_worker.js flutter.js.map
find . -name '*.symbols' -delete
rm -rf canvaskit/skwasm* canvaskit/wimp* canvaskit/webparagraph
if find . -mindepth 1 -name '[._]*' | grep -q .; then
  echo "error: a file or folder name starts with . or _ (Jekyll would drop it):" >&2
  find . -mindepth 1 -name '[._]*' >&2
  exit 1
fi
du -sh "$root/prueba"
