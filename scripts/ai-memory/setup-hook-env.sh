#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

if [[ -x ".venv/bin/python" ]]; then
  echo "Hook Python environment already exists at .venv"
  exit 0
fi

if command -v python3 >/dev/null 2>&1; then
  python3 -m venv .venv
  echo "Created .venv for hook execution"
  exit 0
fi

if command -v uv >/dev/null 2>&1; then
  echo "python3 not found; uv script mode can still run hook_memory.py directly"
  exit 0
fi

echo "Neither python3 nor uv is available; install one runtime first." >&2
exit 1
