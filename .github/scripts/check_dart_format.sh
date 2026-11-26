#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage: check_dart_format.sh [--base <ref>]
EOF
}

base_arg=""

while [ $# -gt 0 ]; do
  case "$1" in
    --base)
      if [ $# -lt 2 ] || [ -z "$2" ]; then
        echo "Error: --base requires a non-empty ref argument." >&2
        usage
        exit 2
      fi
      base_arg="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Error: unknown argument '$1'." >&2
      usage
      exit 2
      ;;
  esac
done

resolve_diff_base() {
  local env_base="${BASE_REF:-}"
  if [ -n "$base_arg" ]; then
    if git rev-parse --verify --quiet "${base_arg}^{commit}" >/dev/null; then
      printf '%s\n' "$base_arg"
      return 0
    fi
    echo "Error: --base ref '${base_arg}' does not resolve to a commit." >&2
    return 1
  fi

  if [ -n "$env_base" ]; then
    if git rev-parse --verify --quiet "origin/${env_base}^{commit}" >/dev/null; then
      printf 'origin/%s\n' "$env_base"
      return 0
    fi
    if git rev-parse --verify --quiet "${env_base}^{commit}" >/dev/null; then
      printf '%s\n' "$env_base"
      return 0
    fi
    echo "Error: BASE_REF '${env_base}' does not resolve to origin/${env_base} or ${env_base}." >&2
    return 1
  fi

  if git rev-parse --verify --quiet "origin/main^{commit}" >/dev/null; then
    printf 'origin/main\n'
    return 0
  fi
  if git rev-parse --verify --quiet "main^{commit}" >/dev/null; then
    printf 'main\n'
    return 0
  fi
  echo "Error: neither origin/main nor main resolves to a commit." >&2
  return 1
}

DIFF_BASE="$(resolve_diff_base)"
CHANGED_DART="$(git diff --name-only --diff-filter=AM "${DIFF_BASE}...HEAD" -- '*.dart' || true)"

DART_FILES=()
if [ -n "$CHANGED_DART" ]; then
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    DART_FILES+=("$f")
  done <<< "$CHANGED_DART"
fi

if [ "${#DART_FILES[@]}" -gt 0 ]; then
  dart format --output=none --set-exit-if-changed "${DART_FILES[@]}"
else
  echo "No Dart files changed."
fi
