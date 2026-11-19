#!/usr/bin/env bash
# Every check of a branch, in the order CI runs them. CI calls this script, so the two cannot drift.
#
#   bash tool/test_all.sh            (from anywhere; it moves to coqui/ itself)
#
# Chrome: `dart test -p chrome` needs a Chrome. If it is not on the PATH, set CHROME_EXECUTABLE first
# (see AGENTS.md, "Machine notes").
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

step() { printf '\n== %s\n' "$*"; }

step "Flutter is the pinned version"
pinned="$(tr -d '[:space:]' < .flutter-version)"
running="$(flutter --version --machine | grep -o '"frameworkVersion": *"[^"]*"' | grep -o '[0-9][0-9.]*[0-9]')"
if [ "$running" != "$pinned" ]; then
  echo "Flutter $running is installed, but coqui/.flutter-version pins $pinned" >&2
  exit 1
fi
echo "Flutter $running"

step "flutter pub get"
flutter pub get

step "boundary check"
dart run tool/check_boundaries.dart

step "dart format"
# The same as `dart format --output=none --set-exit-if-changed .`, without the standalone
# app in tool/prueba_telefono/ (it is not part of the workspace).
find . -name '*.dart' \
  -not -path './tool/prueba_telefono/*' \
  -not -path '*/.dart_tool/*' \
  -not -path '*/build/*' \
  -print0 | xargs -0 dart format --output=none --set-exit-if-changed

step "flutter analyze"
flutter analyze

step "tests: the boundary check's own"
dart test tool/test

# Pure Dart packages (no Flutter SDK in their pubspec) run on the VM and in Chrome.
# Flutter packages run with flutter test.
for dir in packages/core/* packages/features/* app; do
  [ -d "$dir/test" ] || continue
  if grep -q 'sdk: flutter' "$dir/pubspec.yaml"; then
    step "tests: $dir (flutter test)"
    (cd "$dir" && flutter test)
  else
    step "tests: $dir (dart test, vm)"
    (cd "$dir" && dart test -p vm)
    step "tests: $dir (dart test, chrome)"
    (cd "$dir" && dart test -p chrome)
  fi
done

step "flutter build web"
(cd app && flutter build web)

printf '\n== all checks passed\n'
