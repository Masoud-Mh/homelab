#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = []
# ///

from __future__ import annotations

import json
import os
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MEMORY_DIR = ROOT / ".ai" / "memory"
RUNTIME_DIR = MEMORY_DIR / "runtime"
EVENTS_FILE = RUNTIME_DIR / "events.ndjson"
LATEST_FILE = RUNTIME_DIR / "latest-hook-context.md"
ENFORCE_FILE = MEMORY_DIR / "enforce-memory-update.flag"


def ensure_dirs() -> None:
    RUNTIME_DIR.mkdir(parents=True, exist_ok=True)


def safe_read(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except Exception:
        return ""


def append_event(payload: dict) -> None:
    record = {
        "ts": datetime.now(timezone.utc).isoformat(),
        "event": payload.get("hookEventName", "unknown"),
        "sessionId": payload.get("sessionId", ""),
        "cwd": payload.get("cwd", ""),
        "transcript": payload.get("transcript_path", ""),
    }
    with EVENTS_FILE.open("a", encoding="utf-8") as f:
        f.write(json.dumps(record, ensure_ascii=False) + "\n")


def update_latest_context(payload: dict) -> None:
    event = payload.get("hookEventName", "unknown")
    content = (
        "# Latest Hook Context\n\n"
        f"- Event: {event}\n"
        f"- Session: {payload.get('sessionId', '')}\n"
        f"- Timestamp (UTC): {datetime.now(timezone.utc).isoformat()}\n"
        f"- Transcript path: {payload.get('transcript_path', '')}\n"
    )
    LATEST_FILE.write_text(content, encoding="utf-8")


def has_memory_marker(transcript_path: str) -> bool:
    if not transcript_path:
        return False
    text = safe_read(Path(transcript_path))
    return "[MEMORY_UPDATED]" in text


def output(data: dict) -> None:
    print(json.dumps(data, ensure_ascii=False))


def main() -> None:
    ensure_dirs()

    raw = os.sys.stdin.read().strip()
    payload = json.loads(raw) if raw else {}

    append_event(payload)
    update_latest_context(payload)

    event = payload.get("hookEventName", "")

    if event == "SessionStart":
        output(
            {
                "continue": True,
                "hookSpecificOutput": {
                    "hookEventName": "SessionStart",
                    "additionalContext": (
                        "Load .ai/memory files before coding. Update memory files before finishing, "
                        "then include [MEMORY_UPDATED]. Prioritize frontend roadmap first, then section 5 batches."
                    ),
                },
            }
        )
        return

    if event == "PreCompact":
        output(
            {
                "continue": True,
                "systemMessage": "Context compaction triggered; summarize and persist key decisions in .ai/memory before continuing.",
            }
        )
        return

    if event == "Stop":
        stop_hook_active = bool(payload.get("stop_hook_active", False))
        enforce = ENFORCE_FILE.exists()
        has_marker = has_memory_marker(payload.get("transcript_path", ""))

        if enforce and (not stop_hook_active) and (not has_marker):
            output(
                {
                    "continue": True,
                    "hookSpecificOutput": {
                        "hookEventName": "Stop",
                        "decision": "block",
                        "reason": "Update .ai/memory files and include [MEMORY_UPDATED] before ending the session.",
                    },
                }
            )
            return

    output({"continue": True})


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        output(
            {
                "continue": True,
                "systemMessage": f"Memory hook warning: {exc}",
            }
        )
