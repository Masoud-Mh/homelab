#!/usr/bin/env bash
# Session-guard usage entrypoint.
# Emits exactly ONE normalized JSON object on stdout and ALWAYS exits 0.
# Primary source: `claude -p "/usage"` (authoritative). Fallback: ccusage JSON.
#
# Flags:
#   --fast   skip the slow ccusage fallback (for hook time budgets)
set -uo pipefail

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
. "$SOURCE_DIR/lib.sh"

FAST=0
for arg in "$@"; do
  case "$arg" in
    --fast) FAST=1 ;;
  esac
done

CACHE_FILE="$RUNTIME_DIR/usage-last.json"
CACHE_TTL="${SG_CACHE_TTL:-300}"

emit() {
  # Print the JSON object, log a copy, cache good reads, and exit cleanly.
  printf '%s\n' "$1"
  sg_log "$1"
  # Cache only successful (non-"none") reads for the --fast fallback.
  if printf '%s' "$1" | grep -q '"ok": true'; then
    sg_ensure_runtime_dir
    printf '%s\n' "$1" >"$CACHE_FILE" 2>/dev/null || true
  fi
  exit 0
}

# Re-emit a recent cached read if it is fresher than CACHE_TTL seconds.
try_cache() {
  [[ -f "$CACHE_FILE" ]] || return 1
  local mtime age cached
  mtime="$(date -r "$CACHE_FILE" +%s 2>/dev/null)" || return 1
  age=$(( $(date -u +%s) - mtime ))
  (( age <= CACHE_TTL )) || return 1
  cached="$(cat "$CACHE_FILE" 2>/dev/null)" || return 1
  [[ -n "$cached" ]] || return 1
  emit "$cached"
}

emit_none() {
  local msg="$1"
  local out
  out="$(printf '' | sg_run_parser --source none --error "$msg" 2>/dev/null)" || out=""
  if [[ -z "$out" ]]; then
    # Last-resort hand-built object if even the parser/runtime is unavailable.
    out="{\"schema_version\":1,\"source\":\"none\",\"ok\":false,\"recommendation\":\"proceed_unknown\",\"advice\":\"Usage unavailable; proceed cautiously.\",\"error\":\"$msg\"}"
  fi
  emit "$out"
}

# --- Primary: claude -p "/usage" (exact allowlisted form: timeout 5) ---
raw_usage=""
# 8s gives `claude -p /usage` enough headroom (it intermittently exceeds 5s).
# This is an internal child process, not an agent-issued (allowlisted) command.
raw_usage="$(timeout "${SG_USAGE_TIMEOUT:-8}" claude -p "/usage" 2>/dev/null)" || raw_usage=""
if [[ -n "$raw_usage" ]]; then
  parsed="$(printf '%s' "$raw_usage" | sg_run_parser --source usage 2>/dev/null)" || parsed=""
  if [[ -n "$parsed" ]] && printf '%s' "$parsed" | grep -q '"source": "usage"'; then
    emit "$parsed"
  fi
fi

# --- Fallback: ccusage (skipped in --fast mode) ---
if [[ "$FAST" -eq 0 ]]; then
  raw_cc=""
  raw_cc="$(timeout 30 npx -y ccusage blocks --active --json 2>/dev/null)" || raw_cc=""
  if [[ -n "$raw_cc" ]]; then
    parsed="$(printf '%s' "$raw_cc" | sg_run_parser --source ccusage 2>/dev/null)" || parsed=""
    if [[ -n "$parsed" ]] && printf '%s' "$parsed" | grep -q '"source": "ccusage"'; then
      emit "$parsed"
    fi
  fi
fi

# --- Live sources unavailable: try a fresh cached read before giving up ---
try_cache || true

if [[ "$FAST" -eq 1 ]]; then
  emit_none "usage unavailable in --fast mode (claude -p /usage failed, no fresh cache)"
else
  emit_none "both /usage and ccusage unavailable (no fresh cache)"
fi
