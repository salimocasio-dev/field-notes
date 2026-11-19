#!/usr/bin/env bash
# Builds the web app as the live site wants it, into a folder.
#
#   bash tool/build_sitio.sh <out dir>          (from anywhere; it moves to coqui/ itself)
#   COQUI_BUILD=12 bash tool/build_sitio.sh <out dir>
#
# The workflow .github/workflows/coqui-sitio.yml calls this script, so the workflow and a person
# on this machine run the same steps. The workflow then puts <out dir> into app/ at the repo root.
#
# COQUI_BUILD is the build number the app shows ("build 12"). Without it the app shows "build dev".
# <out dir> must not exist, or be empty.
#
# What it does, in order:
#   1. flutter pub get at coqui/
#   2. flutter build web --release, served from /field-notes/app/, CanvasKit from our own site
#      (never from gstatic), the build number compiled in, no service worker
#   3. takes out what the site must not carry: the service worker file, .last_build_id, the
#      source maps and the debug symbols
#   4. fails if anything in the result would be dropped by GitHub Pages (Jekyll drops every name
#      that starts with "_" or "."), if a file starts with Jekyll front matter, if anything could
#      register a service worker, or if the base path or the build number did not get in
set -euo pipefail

[ $# -eq 1 ] || { echo "usage: bash tool/build_sitio.sh <out dir>" >&2; exit 2; }
out="$(realpath -m "$1")"
build="${COQUI_BUILD:-dev}"
[[ "$build" =~ ^([0-9]+|dev)$ ]] || { echo "COQUI_BUILD must be a number or 'dev', not '$build'" >&2; exit 2; }
if [ -e "$out" ] && [ -n "$(ls -A "$out" 2>/dev/null)" ]; then
  echo "$out exists and is not empty. Remove it first." >&2
  exit 2
fi

cd "$(dirname "${BASH_SOURCE[0]}")/.."

step() { printf '\n== %s\n' "$*"; }
fail() { echo "build_sitio: $*" >&2; exit 1; }

step "flutter pub get"
flutter pub get

step "flutter build web (build $build)"
# --no-web-resources-cdn: CanvasKit comes from our own site, never from gstatic.
# --pwa-strategy=none: no service worker (a hidden option of this Flutter; it also leaves the
#   service worker settings out of flutter_bootstrap.js, so nothing registers one).
(cd app && flutter build web --release \
  --base-href /field-notes/app/ \
  --no-web-resources-cdn \
  --pwa-strategy=none \
  --dart-define=COQUI_BUILD="$build" \
  -o "$out")

step "take out what the site must not carry"
# The tool still writes flutter_service_worker.js (empty with --pwa-strategy=none).
rm -f "$out/flutter_service_worker.js" "$out/.last_build_id"
find "$out" -type f \( -name '*.map' -o -name '*.symbols' \) -delete
# A script's last line may point at a source map that is no longer there.
find "$out" -type f -name '*.js' -exec sed -i '/^\/\/# sourceMappingURL=.*\.map$/d' {} +

step "check the result"
# Pages runs Jekyll, which drops every file and folder whose name starts with "_" or ".".
dropped="$(find "$out" -mindepth 1 \( -name '_*' -o -name '.*' \))"
[ -z "$dropped" ] || fail "names that GitHub Pages would drop:
$dropped"
# A file that starts with "---" is read by Jekyll as front matter.
while IFS= read -r -d '' f; do
  ! head -c 4 "$f" | cmp -s - <(printf -- '---\n') || fail "starts with Jekyll front matter: $f"
done < <(find "$out" -type f -print0)
[ ! -e "$out/flutter_service_worker.js" ] || fail "a service worker file is left"
# Nothing may register a service worker: the bootstrap starts the loader with no settings
# (_flutter.loader.load();), and nothing else calls it.
[ "$(grep -c '_flutter\.loader\.load(' "$out/flutter_bootstrap.js")" = 1 ] \
  && grep -q '_flutter\.loader\.load();' "$out/flutter_bootstrap.js" \
  || fail "flutter_bootstrap.js starts the loader with settings (a service worker would be registered)"
grep -q 'navigator.serviceWorker' "$out/index.html" \
  && fail "index.html registers a service worker"
grep -q '<base href="/field-notes/app/">' "$out/index.html" || fail "index.html has the wrong base href"
grep -q "build $build" "$out/main.dart.js" || fail "main.dart.js does not hold 'build $build'"
[ -f "$out/manifest.json" ] && [ -f "$out/icons/Icon-192.png" ] && [ -f "$out/icons/Icon-512.png" ] \
  && [ -f "$out/icons/Icon-maskable-192.png" ] && [ -f "$out/icons/Icon-maskable-512.png" ] \
  && [ -f "$out/favicon.png" ] || fail "the manifest or an icon is missing"

printf '\n== built %s files, %s, in %s\n' \
  "$(find "$out" -type f | wc -l | tr -d ' ')" "$(du -sh "$out" | cut -f1)" "$out"
