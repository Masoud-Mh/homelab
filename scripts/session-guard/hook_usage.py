#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = []
# ///
"""Session-guard hook handler.

Reads the hook payload on stdin, runs check-usage.sh --fast, and returns a hook
JSON object that surfaces the current usage as additionalContext. Advisory only
— it NEVER sleeps (hooks have a ~20s budget). Auto-sleep is the agent's job via
wait-until-reset.sh / the MCP wait_for_reset tool.

Graceful by contract: on any error it prints {"continue": true} and exits 0.
"""

from __future__ import annotations

import json
import os
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CHECK = ROOT / "scripts" / "session-guard" / "check-usage.sh"

# Block (permissionDecision=ask) instead of merely advising when CRITICAL.
BLOCK_ON_CRITICAL = os.environ.get("SG_BLOCK_ON_CRITICAL", "0") == "1"


def out(data: dict) -> None:
    print(json.dumps(data, ensure_ascii=False))


def read_usage() -> dict:
    # SG_CHECK_CMD overrides the usage command (test seam); defaults to the script.
    cmd = os.environ.get("SG_CHECK_CMD")
    args = cmd.split() if cmd else ["bash", str(CHECK), "--fast"]
    proc = subprocess.run(args, capture_output=True, text=True, timeout=15)
    return json.loads(proc.stdout.strip())


def summarize(u: dict) -> str:
    if not u.get("ok"):
        return "Session-guard: usage unknown (sources unavailable); proceed cautiously, re-check before any large fan-out."
    parts = []
    if isinstance(u.get("session_pct"), int):
        reset = u.get("session_reset_human") or "?"
        parts.append(f"session {u['session_pct']}% (resets {reset})")
    if isinstance(u.get("week_pct"), int):
        parts.append(f"week {u['week_pct']}%")
    head = "Session-guard usage: " + ", ".join(parts) if parts else "Session-guard usage:"
    return f"{head}. Recommendation: {u.get('recommendation')} — {u.get('advice')}"


def main() -> None:
    raw = sys.stdin.read().strip()
    payload = json.loads(raw) if raw else {}
    event = payload.get("hookEventName", "")

    usage = read_usage()
    summary = summarize(usage)
    rec = usage.get("recommendation")

    # SessionStart also carries the standing policy reminder.
    if event == "SessionStart":
        summary += (
            " | Policy: check usage before any subagent fan-out and between major "
            "tasks; reason adaptively (remaining session+week %, model in use, task "
            "size, fan-out). If work can't finish within the window, persist state to "
            ".ai/memory/active-context.md and auto-sleep until reset (wait_for_reset / "
            "wait-until-reset.sh), then resume."
        )

    # PreToolUse(Task) is the fan-out gate. Optionally hard-ask at CRITICAL.
    if event == "PreToolUse" and rec == "defer_and_sleep":
        summary += (
            " | CRITICAL before subagent spawn: per policy, persist state and "
            "auto-sleep until reset BEFORE fanning out."
        )
        if BLOCK_ON_CRITICAL:
            out({
                "continue": True,
                "hookSpecificOutput": {
                    "hookEventName": "PreToolUse",
                    "permissionDecision": "ask",
                    "permissionDecisionReason": summary,
                },
            })
            return

    out({
        "continue": True,
        "hookSpecificOutput": {
            "hookEventName": event or "SessionStart",
            "additionalContext": summary,
        },
    })


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:  # never block the session
        ts = datetime.now(timezone.utc).isoformat()
        out({"continue": True, "systemMessage": f"Session-guard hook warning [{ts}]: {exc}"})
