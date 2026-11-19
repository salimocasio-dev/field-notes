#!/usr/bin/env bash
# Order 17: remakes the test fixtures from the old code and the real files under historia/.
#
#   bash tool/make_fixtures.sh            (from anywhere; needs node 22 and the Dart SDK)
#
# It runs the old functions (cual.js cualCarga, app.html pares and oidoEn) in node over the real tree and over the small
# course cut from it (see old_code.mjs, make_expected.mjs, make_fixture.mjs), writes
#   test/fixture/real_expected.json   (read by test/real_tree_test.dart, vm only)
#   test/fixture/small_tree.dart      (the small course, as Dart strings)
#   test/fixture/small_expected.dart  (what the old code answers over it)
# and formats the Dart ones. It then says whether any of the three changed. A run over unchanged files in historia/ and
# in this folder changes nothing: the output is byte for byte the same.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

files=(test/fixture/real_expected.json test/fixture/small_tree.dart test/fixture/small_expected.dart)
before="$(cat "${files[@]}" 2>/dev/null | sha256sum || true)"

node tool/make_expected.mjs
node tool/make_fixture.mjs
dart format test/fixture >/dev/null

after="$(cat "${files[@]}" | sha256sum)"
if [ "$before" = "$after" ]; then
  echo "fixtures: unchanged (byte for byte)"
else
  echo "fixtures: changed"
fi
