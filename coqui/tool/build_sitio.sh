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
#   3. fails if the build's config (in flutter_bootstrap.js) names a renderer other than
#      canvaskit or a compile target other than dart2js: the next step drops the files of the
#      other kinds, so a Flutter whose default changed must not go through silently
#   4. takes out what the site must not carry: the service worker file, .last_build_id, the
#      source maps and the debug symbols, and the skwasm, wimp and webparagraph CanvasKit
#      variants (a dart2js + CanvasKit build loads only canvaskit/ and canvaskit/chromium/)
#   5. fails if anything in the result would be dropped by GitHub Pages (Jekyll drops every name
#      that starts with "_" or "."), if a file starts with Jekyll front matter, if anything could
#      register a service worker, if canvaskit/ holds anything but the four files kept, or if
#      the base path or the build number did not get in
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

step "the build is dart2js + CanvasKit"
# flutter_bootstrap.js holds `_flutter.buildConfig = {...};`. Every build it lists that names a
# renderer or a compile target must name canvaskit and dart2js (an entry that names neither is
# fine), and one entry must name both. The loader starts with no settings (checked below), so
# it cannot be asked for the skwasm or webparagraph variants either.
python3 -I - "$out/flutter_bootstrap.js" <<'PY' || fail "the build is not dart2js + CanvasKit; the next step would drop files it needs"
import json, re, sys
src = open(sys.argv[1], encoding="utf-8").read()
m = re.search(r"_flutter\.buildConfig\s*=\s*", src)
if not m:
    sys.exit("no _flutter.buildConfig in flutter_bootstrap.js")
cfg, _ = json.JSONDecoder().raw_decode(src, m.end())
builds = cfg.get("builds") or []
print("buildConfig builds:", json.dumps(builds), "useLocalCanvasKit:", cfg.get("useLocalCanvasKit"))
bad = [b for b in builds if b.get("renderer", "canvaskit") != "canvaskit" or b.get("compileTarget", "dart2js") != "dart2js"]
if bad:
    sys.exit("builds that are not dart2js + canvaskit: %s" % json.dumps(bad))
if not any(b.get("renderer") == "canvaskit" and b.get("compileTarget") == "dart2js" for b in builds):
    sys.exit("no build entry names dart2js + canvaskit")
if cfg.get("useLocalCanvasKit") is not True:
    sys.exit("useLocalCanvasKit is not true: CanvasKit would come from gstatic")
PY

step "take out what the site must not carry"
# The tool still writes flutter_service_worker.js (empty with --pwa-strategy=none).
rm -f "$out/flutter_service_worker.js" "$out/.last_build_id"
find "$out" -type f \( -name '*.map' -o -name '*.symbols' \) -delete
# CanvasKit variants a dart2js + CanvasKit build never loads: skwasm and wimp belong to the other
# renderer; webparagraph is loaded only when the loader is given preferWebParagraph (it is not).
rm -rf "$out"/canvaskit/skwasm* "$out"/canvaskit/wimp* "$out/canvaskit/webparagraph"
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
# canvaskit/ holds exactly what is loaded: the full variant (Safari, Firefox) and the Chromium one.
kept="canvaskit/canvaskit.js
canvaskit/canvaskit.wasm
canvaskit/chromium/canvaskit.js
canvaskit/chromium/canvaskit.wasm"
[ "$(cd "$out" && find canvaskit -type f | LC_ALL=C sort)" = "$kept" ] \
  || fail "canvaskit/ does not hold exactly the four files kept; it holds: $(cd "$out" && find canvaskit -type f | LC_ALL=C sort | tr '\n' ' ')"
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
