#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
HOOK_SCRIPT="$ROOT_DIR/scripts/ai-memory/hook_memory.py"
VENV_PYTHON="$ROOT_DIR/.venv/bin/python"

if [[ -x "$VENV_PYTHON" ]]; then
  exec "$VENV_PYTHON" "$HOOK_SCRIPT"
fi

if command -v uv >/dev/null 2>&1; then
  exec uv run --script "$HOOK_SCRIPT"
fi

if command -v python3 >/dev/null 2>&1; then
  exec python3 "$HOOK_SCRIPT"
fi

if command -v python >/dev/null 2>&1; then
  exec python "$HOOK_SCRIPT"
fi

printf '%s\n' '{"continue": true, "systemMessage": "No Python runtime found for memory hook (checked .venv, uv, python3, python)."}'
