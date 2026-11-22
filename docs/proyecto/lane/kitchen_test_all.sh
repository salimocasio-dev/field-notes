#!/usr/bin/env bash
# kitchen_test_all.sh WORKTREE LOG : test_all.sh's steps to the END (no stop at the first failure), with the ten new
# single words in palabras-solas.json for the run (restored afterwards). Prints the failing tests at the end.
W="$1"; L="$2"; S=/tmp/claude-0/-home-user-field-notes/869ef226-e8c5-5d2f-b5ba-ad271f43401a/scratchpad
cd "$W" || exit 2
[ -z "$(git status --porcelain)" ] || { echo "worktree not clean" > "$L"; exit 2; }
cp "$S/o06c/palabras-solas.json" historia/cuentos/palabras-solas.json
sed 's/^set -euo pipefail/set -uo pipefail/' coqui/tool/test_all.sh > coqui/tool/.test_all_continue.sh
bash coqui/tool/.test_all_continue.sh > "$L" 2>&1
rm -f coqui/tool/.test_all_continue.sh
git checkout -- historia/cuentos/palabras-solas.json
{
echo; echo "=== SUMMARY"
echo "worktree clean after: $([ -z "$(git status --porcelain)" ] && echo yes || echo NO)"
echo "--- failing dart/flutter tests ([E] lines, de-duplicated):"
grep -aE "\[E\]" "$L" | sed -E 's/^[0-9:]+ \+[0-9]+( ~[0-9]+)?( -[0-9]+)?: //' | sed -E 's/ \[E\].*//' | sort -u
echo "--- python failures:"; grep -aE "^(FAIL|ERROR): |FAILED \(" "$L" | sort -u
echo "--- other error lines:"; grep -aE "^(error|Error:|Unhandled exception)|issues found|--check.*(stale|differs)|is not what|Some tests failed|Failed to" "$L" | sort | uniq -c | head -20
echo "exit done"
} >> "$L"
