---
description: Report Claude Max session/weekly usage and advise whether to proceed, throttle, or auto-sleep until reset
allowed-tools: Bash(scripts/session-guard/check-usage.sh:*), Bash(bash scripts/session-guard/check-usage.sh:*), Bash(timeout 5 claude -p "/usage"), Bash(timeout 30 npx -y ccusage blocks --active --json)
---

Run `bash scripts/session-guard/check-usage.sh` and parse the single JSON object it prints (it always exits 0). Then present a concise report:

1. **Usage:** session `session_pct`% (resets `session_reset_human`), week `week_pct`%, and which `source` was used (`usage` = authoritative `/usage`; `ccusage` = approximate 5h-block proxy, no weekly view; `none` = unavailable).
2. **Recommendation:** restate `recommendation` + `advice`, then add your own adaptive judgment for any work the user mentioned — weigh remaining session AND week %, the **model in use** (Opus burns far faster than Sonnet/Haiku), task complexity, and subagent fan-out. The `thresholds` (warn/critical) are advisory inputs, not hard gates.
3. **If `recommendation` is `defer_and_sleep`:** state the reset time and that project policy is to persist state to `.ai/memory/active-context.md` and auto-sleep until reset (launch `scripts/session-guard/wait-until-reset.sh` with `run_in_background`, or call the `session-guard` MCP `wait_for_reset` tool), then resume — not abandon the task.
4. **If `source` is `none`:** report usage as unknown, proceed cautiously, and re-check shortly.

Keep it to 3–5 lines. Never print secrets or `.env` contents.
