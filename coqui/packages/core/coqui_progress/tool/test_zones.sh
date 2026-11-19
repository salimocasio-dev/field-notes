#!/usr/bin/env bash
# Runs the whole test suite of coqui_progress four times: TZ=UTC and TZ=America/New_York, each on the
# VM and in Chrome, because palabras.js mixes local time and UTC and numbers behave differently on a
# phone and in a browser. Each run replays the recordings of the zone it detects (test/replay_test.dart
# says which zone that was, in its first test name: look for "detected zone"): the 31 sequences of
# coqui/ref/progress/, and the sequences made from historia/app.html (tool/app_sequences.mjs).
#
#   bash tool/test_zones.sh            (from anywhere; it moves to the package itself)
#
# Chrome takes its zone from the TZ of the process that starts it, so TZ is set on `dart test`.
# Needs Chrome: CHROME_EXECUTABLE defaults to /opt/sdk/chrome-nosandbox.sh (AGENTS.md, "Machine notes").
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
export CHROME_EXECUTABLE="${CHROME_EXECUTABLE:-/opt/sdk/chrome-nosandbox.sh}"

log="$(mktemp)"
events="$(mktemp)"
trap 'rm -f "$log" "$events"' EXIT
failed=0
summary=()

# The reporter on the screen does not print every test name when suites run side by side, so the
# names that prove the zone and the totals are read from the JSON event log of the same run.
name_of() { grep -o "\"name\":\"[^\"]*$1[^\"]*\"" "$events" | head -1 | sed 's/^"name":"//; s/"$//; s|^test/replay_test.dart: ||'; }

for tz in UTC America/New_York; do
  for platform in vm chrome; do
    printf '\n== TZ=%s dart test -p %s\n' "$tz" "$platform"
    TZ="$tz" dart test -p "$platform" -r expanded --file-reporter "json:$events" >"$log" 2>&1
    code=$?
    detected="$(name_of 'detected zone')"
    compared="$(name_of 'compared [0-9]* sequences')"
    app="$(name_of 'compared [0-9]* app.html sequences')"
    last="$(grep -E 'All tests passed|Some tests failed' "$log" | tail -1)"
    if [ "$code" -ne 0 ]; then
      failed=1
      grep -v -E 'Woah|strongly|^  /$|📎' "$log" | tail -60
    fi
    echo "$detected"
    echo "$compared"
    echo "$app"
    echo "$last"
    summary+=("TZ=$tz  -p $platform: exit $code | ${detected:-NO ZONE LINE} | ${compared:-NO TOTALS LINE} | ${app:-NO APP.HTML TOTALS LINE} | $last")
  done
done

printf '\n== summary\n'
printf '%s\n' "${summary[@]}"
if [ "$failed" -ne 0 ]; then
  echo "FAILED"
  exit 1
fi
echo "all four runs passed"
