#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = []
# ///
"""Normalize Claude Code usage into a single JSON object.

Reads raw input on stdin and emits exactly one JSON object on stdout, matching
the session-guard contract. Never raises to the caller: on any failure it emits a
well-formed object with source="none" and an error string.

Usage:
    parse_usage.py --source usage     < raw `claude -p "/usage"` text
    parse_usage.py --source ccusage   < `ccusage blocks --active --json` output
    parse_usage.py --source none [--error MSG]
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
import time
from datetime import datetime, timezone

SCHEMA_VERSION = 1

# Soft, advisory thresholds (percent of the binding window used). Env-overridable.
WARN = int(os.environ.get("SG_WARN", "70"))
CRITICAL = int(os.environ.get("SG_CRITICAL", "90"))


def _model_hint() -> str:
    for var in ("CLAUDE_MODEL", "ANTHROPIC_MODEL", "CLAUDE_CODE_MODEL"):
        val = os.environ.get(var, "").lower()
        if "opus" in val:
            return "opus"
        if "sonnet" in val:
            return "sonnet"
        if "haiku" in val:
            return "haiku"
        if val:
            return val
    return "unknown"


def _parse_reset_to_epoch(raw_time: str, tz_label: str | None, now: float) -> int | None:
    """Parse a fragment like 'Jun 17, 4pm' / 'Jun 17, 3:59pm' into a unix epoch.

    If tz_label is 'UTC' the time is interpreted as UTC, otherwise as local time.
    The year is inferred (assume the current year; if that lands in the past by
    more than a day, roll to next year). Returns None on any parse failure.
    """
    raw_time = raw_time.strip().rstrip(".")
    if not raw_time:
        return None
    is_utc = bool(tz_label) and tz_label.upper() in ("UTC", "GMT")
    year = datetime.now(timezone.utc).year if is_utc else datetime.now().year
    candidate = f"{raw_time} {year}"
    parsed = None
    for fmt in ("%b %d, %I:%M%p %Y", "%b %d, %I%p %Y",
                "%B %d, %I:%M%p %Y", "%B %d, %I%p %Y"):
        try:
            parsed = datetime.strptime(candidate, fmt)
            break
        except ValueError:
            continue
    if parsed is None:
        return None
    if is_utc:
        parsed = parsed.replace(tzinfo=timezone.utc)
        epoch = parsed.timestamp()
    else:
        # Naive -> interpret in local tz.
        epoch = parsed.timestamp()
    # Year inference guard: if the result is well in the past, try next year.
    if epoch < now - 86400:
        try:
            epoch = parsed.replace(year=parsed.year + 1).timestamp()
        except ValueError:
            pass
    return int(epoch)


def parse_usage_text(text: str, now: float) -> dict:
    """Parse `/usage` human text. Missing fields stay None; object still returned."""
    session_pct = None
    week_pct = None
    session_reset_epoch = None
    week_reset_epoch = None
    session_reset_human = None

    def reset_from_line(line: str) -> tuple[int | None, str | None]:
        m = re.search(r"(?i)resets?\s+(.+?)\s*(?:\(([A-Za-z]{2,4})\))?\s*$", line)
        if not m:
            return None, None
        frag = m.group(1).strip()
        tz_label = m.group(2)
        human = f"{frag} ({tz_label})" if tz_label else frag
        return _parse_reset_to_epoch(frag, tz_label, now), human

    for line in text.splitlines():
        low = line.lower()
        if "current session" in low:
            m = re.search(r"(\d{1,3})\s*%", line)
            if m:
                session_pct = int(m.group(1))
            epoch, human = reset_from_line(line)
            session_reset_epoch = session_reset_epoch or epoch
            session_reset_human = session_reset_human or human
        elif "week" in low:
            m = re.search(r"(\d{1,3})\s*%", line)
            if m:
                # The binding weekly constraint is the highest percentage across
                # the "all models" / per-model weekly lines.
                pct = int(m.group(1))
                week_pct = pct if week_pct is None else max(week_pct, pct)
            epoch, _ = reset_from_line(line)
            week_reset_epoch = week_reset_epoch or epoch

    return {
        "source": "usage",
        "session_pct": session_pct,
        "week_pct": week_pct,
        "session_reset_epoch": session_reset_epoch,
        "week_reset_epoch": week_reset_epoch,
        "session_reset_human": session_reset_human,
    }


def parse_ccusage_json(text: str, now: float) -> dict:
    """Parse `ccusage blocks --active --json`. Yields a proxy session_pct.

    ccusage measures a rolling 5h (300min) token block, not the subscription's
    real session %, so session_pct here is an elapsed-fraction proxy and week_pct
    is unavailable.
    """
    data = json.loads(text)
    blocks = data.get("blocks", []) if isinstance(data, dict) else []
    active = next((b for b in blocks if b.get("isActive")), None)
    if active is None:
        active = blocks[0] if blocks else {}

    session_reset_epoch = None
    end_time = active.get("endTime")
    if end_time:
        try:
            iso = end_time.replace("Z", "+00:00")
            session_reset_epoch = int(datetime.fromisoformat(iso).timestamp())
        except (ValueError, AttributeError):
            session_reset_epoch = None

    session_pct = None
    projection = active.get("projection") or {}
    remaining_min = projection.get("remainingMinutes")
    if isinstance(remaining_min, (int, float)):
        # 5h block = 300 minutes; proxy used fraction.
        session_pct = max(0, min(100, round((1 - remaining_min / 300) * 100)))
    elif session_reset_epoch:
        remaining = session_reset_epoch - now
        session_pct = max(0, min(100, round((1 - remaining / (300 * 60)) * 100)))

    human = None
    if session_reset_epoch:
        human = datetime.fromtimestamp(session_reset_epoch, timezone.utc).strftime(
            "%b %d, %-I:%M%p (UTC)"
        )

    return {
        "source": "ccusage",
        "session_pct": session_pct,
        "week_pct": None,
        "session_reset_epoch": session_reset_epoch,
        "week_reset_epoch": None,
        "session_reset_human": human,
    }


def recommend(session_pct, week_pct) -> tuple[str, str]:
    known = [p for p in (session_pct, week_pct) if isinstance(p, int)]
    if not known:
        return ("proceed_unknown",
                "Usage unknown; proceed cautiously and re-check shortly.")
    binding = max(known)
    if binding >= CRITICAL:
        return ("defer_and_sleep",
                f"Binding window at {binding}% (>= {CRITICAL}%). Persist state, "
                "auto-sleep until reset, then resume.")
    if binding >= WARN:
        return ("proceed_cautiously",
                f"Binding window at {binding}% (>= {WARN}%). Avoid large subagent "
                "fan-out; prefer a cheaper model or split the task.")
    return ("proceed", f"Binding window at {binding}%; safe to proceed.")


def finalize(partial: dict, now: float, error: str | None = None) -> dict:
    session_pct = partial.get("session_pct")
    week_pct = partial.get("week_pct")
    session_reset_epoch = partial.get("session_reset_epoch")
    seconds_to_reset = (
        int(session_reset_epoch - now) if isinstance(session_reset_epoch, int) else None
    )
    source = partial.get("source", "none")
    ok = source != "none"
    recommendation, advice = recommend(session_pct, week_pct)
    if not ok:
        recommendation, advice = (
            "proceed_unknown",
            "Usage sources unavailable; proceed cautiously and re-check shortly.",
        )
    return {
        "schema_version": SCHEMA_VERSION,
        "ts": datetime.fromtimestamp(now, timezone.utc).isoformat(),
        "source": source,
        "ok": ok,
        "session_pct": session_pct,
        "week_pct": week_pct,
        "session_reset_epoch": session_reset_epoch,
        "week_reset_epoch": partial.get("week_reset_epoch"),
        "session_reset_human": partial.get("session_reset_human"),
        "now_epoch": int(now),
        "seconds_to_session_reset": seconds_to_reset,
        "model_hint": _model_hint(),
        "thresholds": {"warn": WARN, "critical": CRITICAL},
        "recommendation": recommendation,
        "advice": advice,
        "error": error,
    }


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--source", choices=("usage", "ccusage", "none"), required=True)
    ap.add_argument("--error", default=None)
    args = ap.parse_args()

    now = time.time()
    try:
        if args.source == "none":
            print(json.dumps(finalize({"source": "none"}, now, error=args.error)))
            return
        raw = sys.stdin.read()
        if not raw.strip():
            raise ValueError("empty input")
        if args.source == "usage":
            partial = parse_usage_text(raw, now)
            if partial.get("session_pct") is None and partial.get("week_pct") is None:
                raise ValueError("no percentages parsed from /usage text")
        else:
            partial = parse_ccusage_json(raw, now)
        print(json.dumps(finalize(partial, now)))
    except Exception as exc:  # never crash the caller
        print(json.dumps(finalize({"source": "none"}, now, error=str(exc))))


if __name__ == "__main__":
    main()
