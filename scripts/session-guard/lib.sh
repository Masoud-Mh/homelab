#!/usr/bin/env bash
# Shared helpers for the session-guard scripts.
# Sourced by check-usage.sh, wait-until-reset.sh, run-usage-hook.sh.
# Mirrors the runtime-detection + path idioms of scripts/ai-memory/.

# Resolve repo root from this file's location (scripts/session-guard/lib.sh -> repo root).
SG_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SG_LIB_DIR/../.." && pwd)"
GUARD_DIR="$ROOT_DIR/scripts/session-guard"
RUNTIME_DIR="$ROOT_DIR/.ai/memory/runtime"
USAGE_LOG="$RUNTIME_DIR/usage-log.ndjson"
WAIT_SENTINEL="$RUNTIME_DIR/session-guard.wait"

sg_ensure_runtime_dir() {
  mkdir -p "$RUNTIME_DIR" 2>/dev/null || true
}

# Echo the first working Python runtime command (matches run-memory-hook.sh order).
# Prints nothing and returns 1 if no runtime is found.
sg_python_cmd() {
  local venv_python="$ROOT_DIR/.venv/bin/python"
  if [[ -x "$venv_python" ]]; then
    printf '%s\n' "$venv_python"
    return 0
  fi
  if command -v uv >/dev/null 2>&1; then
    printf '%s\n' "uv run --script"
    return 0
  fi
  if command -v python3 >/dev/null 2>&1; then
    printf '%s\n' "python3"
    return 0
  fi
  if command -v python >/dev/null 2>&1; then
    printf '%s\n' "python"
    return 0
  fi
  return 1
}

# Run parse_usage.py with the detected runtime, forwarding all args + stdin.
sg_run_parser() {
  local parser="$GUARD_DIR/parse_usage.py"
  local cmd
  if ! cmd="$(sg_python_cmd)"; then
    return 1
  fi
  # shellcheck disable=SC2086
  $cmd "$parser" "$@"
}

# Append a single NDJSON record to the usage log (best-effort, never fails caller).
sg_log() {
  local line="$1"
  sg_ensure_runtime_dir
  printf '%s\n' "$line" >>"$USAGE_LOG" 2>/dev/null || true
}
