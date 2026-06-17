#!/usr/bin/env bash
# Auto-sleep until the usage window resets, then exit so the harness re-invokes
# the agent and the deferred task resumes.
#
# MUST be launched as a BACKGROUND process (the agent's Bash tool blocks
# foreground sleep and caps tool timeouts at 10 min). Inside a detached process,
# foreground sleep is fine; we still chunk it for self-healing on re-entry.
#
# Inputs (env or argv):
#   $1 / SG_TARGET_EPOCH    unix epoch to wait until. If unset, derived from
#                           check-usage.sh (session_reset_epoch).
#   SG_BUFFER_SECONDS       grace added after the reset epoch (default 120).
#   SG_MAX_WAIT_SECONDS     hard guardrail cap (default 21600 = 6h).
#   SG_CHUNK_SECONDS        sleep granularity (default 540 = 9 min).
#   SG_SENTINEL             sentinel path (default .ai/memory/runtime/session-guard.wait).
#
# On exit: removes the sentinel, prints a final usage JSON snapshot, exits 0.
set -uo pipefail

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
. "$SOURCE_DIR/lib.sh"

BUFFER="${SG_BUFFER_SECONDS:-120}"
MAX_WAIT="${SG_MAX_WAIT_SECONDS:-21600}"
CHUNK="${SG_CHUNK_SECONDS:-540}"
SENTINEL="${SG_SENTINEL:-$WAIT_SENTINEL}"

now_epoch() { date -u +%s; }

# Resolve target epoch: argv > env > derived from check-usage.sh.
TARGET="${1:-${SG_TARGET_EPOCH:-}}"
if [[ -z "$TARGET" ]]; then
  snap="$(bash "$SOURCE_DIR/check-usage.sh" 2>/dev/null)" || snap=""
  TARGET="$(printf '%s' "$snap" | grep -o '"session_reset_epoch": *[0-9]*' | grep -o '[0-9]*' | head -n1)"
fi

if [[ -z "$TARGET" || ! "$TARGET" =~ ^[0-9]+$ ]]; then
  printf '%s\n' '{"waited":false,"error":"no valid target epoch; not sleeping"}'
  exit 0
fi

TARGET=$((TARGET + BUFFER))
START="$(now_epoch)"
sg_ensure_runtime_dir
printf '{"target_epoch":%s,"start_epoch":%s,"max_wait_seconds":%s,"pid":%s}\n' \
  "$TARGET" "$START" "$MAX_WAIT" "$$" >"$SENTINEL" 2>/dev/null || true
sg_log "{\"event\":\"wait_start\",\"target_epoch\":$TARGET,\"start_epoch\":$START}"

cleanup() { rm -f "$SENTINEL" 2>/dev/null || true; }
trap cleanup EXIT

while :; do
  cur="$(now_epoch)"
  # Stop conditions: reached target, or hit the max-wait guardrail.
  if (( cur >= TARGET )); then
    break
  fi
  if (( cur - START >= MAX_WAIT )); then
    sg_log "{\"event\":\"wait_capped\",\"now\":$cur,\"max_wait\":$MAX_WAIT}"
    break
  fi
  # Early-exit re-check: if usage has already freed up, stop waiting.
  early="$(bash "$SOURCE_DIR/check-usage.sh" --fast 2>/dev/null)" || early=""
  if printf '%s' "$early" | grep -q '"recommendation": "proceed"'; then
    sg_log "{\"event\":\"wait_early_exit\",\"now\":$cur}"
    break
  fi
  remaining=$((TARGET - cur))
  (( remaining < CHUNK )) && nap="$remaining" || nap="$CHUNK"
  (( nap < 1 )) && nap=1
  sleep "$nap"
done

cleanup
trap - EXIT
final="$(bash "$SOURCE_DIR/check-usage.sh" 2>/dev/null)" || final='{"source":"none","ok":false}'
sg_log "{\"event\":\"wait_complete\",\"now\":$(now_epoch)}"
printf '%s\n' "$final"
exit 0
