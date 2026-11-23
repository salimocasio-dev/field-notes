#!/usr/bin/env bash
# rest_tests.sh WORKTREE LOG FIRSTDIR : test_all.sh's package steps from FIRSTDIR on (to the end, no stop at a failure), then the web build.
W="$1"; L="$2"; FIRST="$3"
cd "$W/coqui" || exit 2
export CHROME_EXECUTABLE=${CHROME_EXECUTABLE:-/opt/sdk/chrome-nosandbox.sh}
: > "$L"; go=0
for dir in packages/core/* packages/features/* app; do
  [ "$dir" = "$FIRST" ] && go=1; [ $go = 1 ] || continue
  [ -d "$dir/test" ] || continue
  if grep -q 'sdk: flutter' "$dir/pubspec.yaml"; then
    echo "== tests: $dir (flutter test)" >> "$L"; (cd "$dir" && flutter test) >> "$L" 2>&1; echo "== exit $? $dir" >> "$L"
  else
    echo "== tests: $dir (dart test, vm)" >> "$L"; (cd "$dir" && dart test -p vm) >> "$L" 2>&1; echo "== exit $? $dir vm" >> "$L"
    echo "== tests: $dir (dart test, chrome)" >> "$L"; (cd "$dir" && dart test -p chrome) >> "$L" 2>&1; echo "== exit $? $dir chrome" >> "$L"
  fi
done
echo "== flutter build web" >> "$L"; (cd app && flutter build web --no-web-resources-cdn) >> "$L" 2>&1; echo "== exit $? build web" >> "$L"
{ echo; echo "=== SUMMARY"; grep -a "^== exit" "$L" | grep -v "^== exit 0"; echo "--- failing ([E], de-duplicated):"
grep -aE "\[E\]" "$L" | sed -E 's/^[0-9:]+ \+[0-9]+( ~[0-9]+)?( -[0-9]+)?: //' | sed -E 's/ \[E\].*//' | sort -u
echo "worktree clean after: $([ -z "$(cd "$W" && git status --porcelain)" ] && echo yes || echo NO)"; echo "exit done"; } >> "$L"
