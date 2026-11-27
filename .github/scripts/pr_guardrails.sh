#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage: pr_guardrails.sh [--base <ref>] [--head-ref <branch>]
EOF
}

base_arg=""
head_ref_arg=""

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
    --head-ref)
      if [ $# -lt 2 ] || [ -z "$2" ]; then
        echo "Error: --head-ref requires a non-empty branch argument." >&2
        usage
        exit 2
      fi
      head_ref_arg="$2"
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

resolve_head_ref() {
  local env_head="${HEAD_REF:-}"
  if [ -n "$head_ref_arg" ]; then
    printf '%s\n' "$head_ref_arg"
  elif [ -n "$env_head" ]; then
    printf '%s\n' "$env_head"
  else
    git rev-parse --abbrev-ref HEAD
  fi
}

DIFF_BASE="$(resolve_diff_base)"
HEAD_REF="$(resolve_head_ref)"
CHANGED="$(git diff --name-only "${DIFF_BASE}...HEAD")"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

check_sensitive_paths() {
  local rc=0
  local cuentos_hit=0
  local app_hit=0
  local f=""

  [ -n "$CHANGED" ] || return 0

  while IFS= read -r f; do
    [ -n "$f" ] || continue
    case "$f" in
      historia/cuentos/*)
        if [ "$cuentos_hit" -eq 0 ]; then
          echo "::error::PR modifies historia/cuentos/ (triggers paid Azure audio). Direct PR edits are blocked."
          cuentos_hit=1
          rc=1
        fi
        ;;
      app/*)
        if [ "$app_hit" -eq 0 ]; then
          echo "::error::PR modifies root app/ directly. Only coqui-sitio.yml may publish to app/ on main."
          app_hit=1
          rc=1
        fi
        ;;
    esac
  done <<< "$CHANGED"

  return "$rc"
}

check_branch_boundaries() {
  local rc=0
  local pkg_lines=""
  local pkgs=""
  local count="0"
  local f=""

  pkg_lines="$(printf '%s\n' "$CHANGED" | grep '^coqui/packages/' || true)"

  if [[ "$HEAD_REF" =~ ^story/[0-9]+$ ]]; then
    if [ -n "$CHANGED" ]; then
      while IFS= read -r f; do
        [ -n "$f" ] || continue
        case "$f" in
          coqui/packages/core/coqui_scenes/*|coqui/packages/features/feature_story/*|coqui/packages/coqui_story_checks/*|coqui/ref/pp/*|coqui/requests/*)
            ;;
          *)
            echo "::error file=$f::story/<n> branch '$HEAD_REF' modifies disallowed path '$f' (allowed: coqui_scenes, feature_story, coqui_story_checks, coqui/ref/pp/, coqui/requests/)."
            rc=1
            ;;
        esac
      done <<< "$CHANGED"
    fi
  elif [[ "$HEAD_REF" =~ ^lane/[^/]+/ ]]; then
    if [ -n "$pkg_lines" ]; then
      pkgs="$(printf '%s\n' "$pkg_lines" | sed -E 's#^coqui/packages/((core|features)/)?([^/]+)(/.*)?$#\1\3#' | sort -u)"
      count="$(printf '%s\n' "$pkgs" | sed '/^$/d' | wc -l | tr -d '[:space:]')"
      if [ "$count" -gt 1 ]; then
        echo "::error::PR touches multiple Flutter packages ($pkgs). One lane branch must change only one package."
        rc=1
      fi
    fi
  else
    if [ -n "$pkg_lines" ]; then
      echo "::error::Branch '$HEAD_REF' modifies coqui/packages/ with an unauthorized prefix. Use lane/<package>/<n> or story/<n>."
      rc=1
    fi
  fi

  return "$rc"
}

check_noche_tokens() {
  local rc=0
  local ui_path="coqui/packages/core/coqui_ui/"
  local dart_files=""
  local f=""
  local hits=""

  dart_files="$(git diff --name-only --diff-filter=AM "${DIFF_BASE}...HEAD" -- 'coqui/packages/*.dart' 'coqui/packages/**/*.dart' | grep -v "^${ui_path}" || true)"
  if [ -z "$dart_files" ]; then
    echo "No non-coqui_ui Dart files changed."
    return 0
  fi

  while IFS= read -r f; do
    [ -n "$f" ] || continue
    hits="$(git diff -U0 "${DIFF_BASE}...HEAD" -- "$f" | grep -E '^\+[^+]' | grep -nE 'Color\(0x|fontFamily[[:space:]]*:' || true)"
    if [ -n "$hits" ]; then
      echo "::error file=$f::Found raw Color(0x...) or fontFamily outside coqui_ui. Use NocheColors/NocheType."
      echo "$hits"
      rc=1
    fi
  done <<< "$dart_files"

  return "$rc"
}

check_noche_motion() {
  local rc=0
  python3 "$SCRIPT_DIR/check_noche_motion.py" --base "$DIFF_BASE" || rc=1
  python3 "$SCRIPT_DIR/test_check_noche_motion.py" || rc=1
  return "$rc"
}

check_codeowners() {
  if [ -f "$REPO_ROOT/.github/CODEOWNERS" ]; then
    python3 "$SCRIPT_DIR/test_codeowners.py"
  fi
}

check_claude_pr_review() {
  python3 "$SCRIPT_DIR/test_claude_pr_review.py"
}

overall_rc=0
check_sensitive_paths || overall_rc=1
check_branch_boundaries || overall_rc=1
check_noche_tokens || overall_rc=1
check_noche_motion || overall_rc=1
check_codeowners || overall_rc=1
check_claude_pr_review || overall_rc=1

exit "$overall_rc"
