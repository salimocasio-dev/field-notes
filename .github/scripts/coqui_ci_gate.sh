#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage: coqui_ci_gate.sh [--base <ref>] [--event <event_name>]
EOF
}

base_arg=""
event_arg=""

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
    --event)
      if [ $# -lt 2 ] || [ -z "$2" ]; then
        echo "Error: --event requires a non-empty event name argument." >&2
        usage
        exit 2
      fi
      event_arg="$2"
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

emit_output() {
  local value="$1"
  local reason="$2"
  if [ -n "${GITHUB_OUTPUT:-}" ]; then
    printf 'run=%s\n' "$value" >> "$GITHUB_OUTPUT"
  fi
  printf 'coqui_ci_gate: run=%s (%s)\n' "$value" "$reason"
}

emit_env() {
  local key="$1"
  local value="$2"
  local clean_value="${value//$'\r'/}"
  clean_value="${clean_value//$'\n'/}"
  if [ -n "${GITHUB_ENV:-}" ]; then
    printf '%s=%s\n' "$key" "$clean_value" >> "$GITHUB_ENV"
  fi
}

resolve_diff_base() {
  local env_base="${BASE_REF:-}"
  local env_base_sha="${BASE_SHA:-}"

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
    if [ -n "$env_base_sha" ] && git rev-parse --verify --quiet "${env_base_sha}^{commit}" >/dev/null; then
      printf '%s\n' "$env_base_sha"
      return 0
    fi
    echo "Error: BASE_REF '${env_base}' does not resolve to origin/${env_base}, ${env_base}, or BASE_SHA." >&2
    return 1
  fi

  if [ -n "$env_base_sha" ]; then
    if git rev-parse --verify --quiet "${env_base_sha}^{commit}" >/dev/null; then
      printf '%s\n' "$env_base_sha"
      return 0
    fi
    echo "Error: BASE_SHA '${env_base_sha}' does not resolve to a commit." >&2
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

event_name="${event_arg:-${EVENT_NAME:-pull_request}}"

if [ "$event_name" != "pull_request" ]; then
  emit_env COQUI_FULL_SUITE 1
  emit_env COQUI_CI_EVENT "$event_name"
  emit_output true "event=${event_name}; running full Coquí check suite"
  exit 0
fi

DIFF_BASE="$(resolve_diff_base)"
CHANGED="$(git -c core.quotepath=false diff --name-only --no-renames "${DIFF_BASE}...HEAD")"

MATCHED=()
if [ -n "$CHANGED" ]; then
  while IFS= read -r path; do
    [ -n "$path" ] || continue
    case "$path" in
      coqui|coqui/*|content|content/*|historia/datos/*|historia/cuentos/*|historia/libros/*|.github/workflows/coqui.yml|.github/scripts/coqui_ci_gate.sh)
        MATCHED+=("$path")
        ;;
    esac
  done <<< "$CHANGED"
fi

if [ "${#MATCHED[@]}" -gt 0 ]; then
  echo "Matched Coquí CI paths (${#MATCHED[@]}):"
  shown=0
  for path in "${MATCHED[@]}"; do
    if [ "$shown" -lt 20 ]; then
      printf '  - %s\n' "$path"
      shown=$((shown + 1))
    fi
  done
  if [ "${#MATCHED[@]}" -gt 20 ]; then
    printf '  ... and %d more\n' "$(( ${#MATCHED[@]} - 20 ))"
  fi
  if [ -n "${GITHUB_ENV:-}" ]; then
    temp_dir="${RUNNER_TEMP:-/tmp}"
    mkdir -p "$temp_dir"
    changed_file="$(mktemp "${temp_dir}/coqui_changed_paths.XXXXXX")"
    while IFS= read -r path; do
      [ -n "$path" ] || continue
      printf '%s\n' "$path" >> "$changed_file"
    done <<< "$CHANGED"
    emit_env COQUI_FULL_SUITE 0
    emit_env COQUI_CI_EVENT "$event_name"
    emit_env COQUI_CHANGED_PATHS_FILE "$changed_file"
  fi
  emit_output true "${#MATCHED[@]} matching path(s) changed against ${DIFF_BASE}"
  exit 0
fi

echo "No changes under coqui/, content/, historia/{datos,cuentos,libros}/, .github/workflows/coqui.yml, or .github/scripts/coqui_ci_gate.sh; skipping heavy Flutter steps."
emit_output false "no matching paths changed against ${DIFF_BASE}"
exit 0
