#!/usr/bin/env bash
# Every check of a branch, in the order CI runs them. CI calls this script, so the two cannot drift.
#
#   bash coqui/tool/test_all.sh                              (full suite; default locally and on main)
#   bash coqui/tool/test_all.sh --base origin/main           (selective: changed packages + dependents)
#   bash coqui/tool/test_all.sh --changed <path> [...]       (selective for explicit repo-relative paths)
#   bash coqui/tool/test_all.sh --changed-file <file>        (selective from newline-separated paths)
#   bash coqui/tool/test_all.sh --dry-run [selection flags]  (print plan and exit 0)
#
# Chrome: `dart test -p chrome` needs a Chrome. If it is not on the PATH, set CHROME_EXECUTABLE first
# (see AGENTS.md, "Machine notes").
set -euo pipefail

CALLER_PWD="$PWD"
COQUI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_ROOT="$(cd "$COQUI_DIR/.." && pwd)"

usage() {
  cat >&2 <<'EOF'
Usage: test_all.sh [options] [path ...]

Options:
  --full                 Force the full check suite (default when no selection is provided)
  --changed <path>       Changed repo-relative path (repeatable)
  --changed-file <file>  File with newline-separated changed repo-relative paths
  --base <ref>           Compute changed paths via git diff <ref>...HEAD
  --dry-run              Print the test plan and exit 0 without running checks
  -h, --help             Show this help message

Environment (used only when no CLI selection flags or paths are given):
  COQUI_FULL_SUITE=1               Force the full check suite
  COQUI_CHANGED_PATHS_FILE=<file>  Path to newline-separated changed repo paths
EOF
}

resolve_from_caller() {
  local p="$1"
  case "$p" in
    /*) printf '%s\n' "$p" ;;
    *) printf '%s/%s\n' "$CALLER_PWD" "$p" ;;
  esac
}

force_full=0
dry_run=0
explicit_selection=0
changed_file_arg=""
base_ref=""
changed_paths=()

while [ $# -gt 0 ]; do
  case "$1" in
    --full)
      force_full=1
      explicit_selection=1
      shift
      ;;
    --changed)
      if [ $# -lt 2 ] || [ -z "$2" ]; then
        echo "Error: --changed requires a non-empty path argument." >&2
        usage
        exit 2
      fi
      changed_paths+=("$2")
      explicit_selection=1
      shift 2
      ;;
    --changed-file)
      if [ $# -lt 2 ] || [ -z "$2" ]; then
        echo "Error: --changed-file requires a non-empty file argument." >&2
        usage
        exit 2
      fi
      changed_file_arg="$(resolve_from_caller "$2")"
      explicit_selection=1
      shift 2
      ;;
    --base)
      if [ $# -lt 2 ] || [ -z "$2" ]; then
        echo "Error: --base requires a non-empty git ref argument." >&2
        usage
        exit 2
      fi
      base_ref="$2"
      explicit_selection=1
      shift 2
      ;;
    --dry-run)
      dry_run=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      while [ $# -gt 0 ]; do
        changed_paths+=("$1")
        explicit_selection=1
        shift
      done
      ;;
    --*)
      echo "Error: unknown option '$1'." >&2
      usage
      exit 2
      ;;
    *)
      changed_paths+=("$1")
      explicit_selection=1
      shift
      ;;
  esac
done

if [ "$explicit_selection" -eq 0 ]; then
  full_env="$(printf '%s' "${COQUI_FULL_SUITE:-0}" | tr '[:upper:]' '[:lower:]')"
  case "$full_env" in
    1|true|yes|on)
      force_full=1
      ;;
    *)
      if [ -n "${COQUI_CHANGED_PATHS_FILE:-}" ]; then
        changed_file_arg="$(resolve_from_caller "$COQUI_CHANGED_PATHS_FILE")"
      else
        force_full=1
      fi
      ;;
  esac
fi

CLEANUP_PATHS=()
cleanup() {
  if [ "${#CLEANUP_PATHS[@]}" -gt 0 ]; then
    rm -rf "${CLEANUP_PATHS[@]}"
  fi
}
trap cleanup EXIT

if [ "$force_full" -eq 0 ] && [ -n "$base_ref" ]; then
  if ! git -C "$REPO_ROOT" rev-parse --verify --quiet "${base_ref}^{commit}" >/dev/null; then
    echo "Error: --base ref '${base_ref}' does not resolve to a commit." >&2
    exit 2
  fi
  base_changed_file="$(mktemp)"
  CLEANUP_PATHS+=("$base_changed_file")
  git -C "$REPO_ROOT" -c core.quotepath=false diff --name-only --no-renames "${base_ref}...HEAD" > "$base_changed_file"
  if [ -n "$changed_file_arg" ]; then
    if [ ! -f "$changed_file_arg" ]; then
      echo "Error: --changed-file does not exist: ${changed_file_arg}" >&2
      exit 2
    fi
    cat "$changed_file_arg" >> "$base_changed_file"
  fi
  changed_file_arg="$base_changed_file"
fi

cd "$COQUI_DIR"

plan_json="$(mktemp)"
CLEANUP_PATHS+=("$plan_json")

plan_cmd=(python3 tool/plan_tests.py --format json)
if [ "$force_full" -eq 1 ]; then
  plan_cmd+=(--full)
else
  if [ -n "$changed_file_arg" ]; then
    plan_cmd+=(--changed-file "$changed_file_arg")
  fi
  if [ "${#changed_paths[@]}" -gt 0 ]; then
    for path in "${changed_paths[@]}"; do
      plan_cmd+=(--changed "$path")
    done
  fi
fi

"${plan_cmd[@]}" > "$plan_json"

python3 - "$plan_json" <<'PY'
import json
import sys

sys.path.insert(0, "tool")
import plan_tests

with open(sys.argv[1], encoding="utf-8") as fh:
    print(plan_tests.format_human_dict(json.load(fh)))
PY

if [ "$dry_run" -eq 1 ]; then
  exit 0
fi

step() { printf '\n== %s\n' "$*"; }

plan_flag() {
  python3 -c 'import json, sys; d = json.load(open(sys.argv[1], encoding="utf-8")); sys.exit(0 if d.get(sys.argv[2]) else 1)' "$plan_json" "$1"
}

plan_mode="$(python3 -c 'import json, sys; print(json.load(open(sys.argv[1], encoding="utf-8"))["mode"])' "$plan_json")"

if plan_flag run_dart_checks || plan_flag run_boundaries_only; then
  step "Flutter is the pinned version"
  pinned="$(tr -d '[:space:]' < .flutter-version)"
  running="$(flutter --version --machine | grep -o '"frameworkVersion": *"[^"]*"' | grep -o '[0-9][0-9.]*[0-9]')"
  if [ "$running" != "$pinned" ]; then
    echo "Flutter $running is installed, but coqui/.flutter-version pins $pinned" >&2
    exit 1
  fi
  echo "Flutter $running"
fi

if plan_flag run_dart_checks; then
  step "flutter pub get"
  flutter pub get

  step "generate shared scene lists"
  dart run tool/make_scenes.dart --check-committed
  dart run tool/make_scenes.dart
  dart run tool/make_scenes.dart --check

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
elif plan_flag run_boundaries_only; then
  step "boundary check"
  dart run tool/check_boundaries.dart
fi

if plan_flag run_tool_tests; then
  step "tests: tool Dart and Python planner tests"
  dart test tool/test
  python3 tool/test/test_plan_tests.py
fi

if plan_flag run_data_checks; then
  step "data: make_repaso.py, make_palabras_solas.py, and make_previa.py"
  python3 tool/test/test_make_repaso.py 2>&1 | tail -n 3
  repaso_tmp="$(mktemp -d)"
  CLEANUP_PATHS+=("$repaso_tmp")
  python3 tool/make_repaso.py --out "$repaso_tmp" --hojas-libro
  python3 tool/make_repaso.py --out "$repaso_tmp" --veredictos tool/repaso/veredictos --hojas-par
  python3 tool/repaso/arrastra.py --check --ahora "$repaso_tmp"
  python3 tool/make_repaso.py --out "$repaso_tmp" --veredictos tool/repaso/veredictos \
    --veredictos-par tool/repaso/veredictos-par --app ../historia/datos/repaso.json --check
  python3 tool/test/test_make_palabras_solas.py 2>&1 | tail -n 3
  python3 tool/make_palabras_solas.py --check
  python3 tool/test/test_make_previa.py 2>&1 | tail -n 3
elif plan_flag run_previa_check; then
  step "data: make_previa.py"
  python3 tool/test/test_make_previa.py 2>&1 | tail -n 3
fi

if plan_flag run_content_checks; then
  step "content: split_stories.py"
  python3 tool/test/test_split_stories.py 2>&1 | tail -n 3
  python3 tool/split_stories.py check
fi

# Pure Dart packages (no Flutter SDK in their pubspec) run on the VM and in Chrome.
# Flutter packages run with flutter test.
while IFS=$'\t' read -r rel_dir is_flutter pkg_name; do
  [ -n "$rel_dir" ] || continue
  if [ "$is_flutter" = "1" ]; then
    step "tests: $rel_dir ($pkg_name, flutter test)"
    (cd "$rel_dir" && flutter test)
  else
    step "tests: $rel_dir ($pkg_name, dart test, vm)"
    (cd "$rel_dir" && dart test -p vm)
    step "tests: $rel_dir ($pkg_name, dart test, chrome)"
    (cd "$rel_dir" && dart test -p chrome)
  fi
done < <(python3 - "$plan_json" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as fh:
    plan = json.load(fh)
for pkg in plan.get("packages_to_test", []):
    flag = "1" if pkg.get("is_flutter") else "0"
    print(f"{pkg['rel_dir']}\t{flag}\t{pkg['name']}")
PY
)

if plan_flag run_web_build; then
  step "flutter build web"
  # --no-web-resources-cdn: CanvasKit comes from our own site, never from gstatic.
  (cd app && flutter build web --no-web-resources-cdn)
fi

printf '\n== all planned checks passed (mode=%s)\n' "$plan_mode"

