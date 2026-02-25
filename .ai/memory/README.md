# AI Memory System

Purpose: mitigate context-window loss across long autonomous sessions.

## Files to read first
- `facts.md`: stable architecture facts and constraints.
- `active-context.md`: current objective, latest status, next actions.
- `roadmap-status.md`: frontend roadmap tracking.
- `batch-status.md`: section-5 technical debt tracking.
- `decisions.md`: architecture and implementation decisions.

## Update policy
- Update memory at the end of each completed batch.
- Keep entries compact and evidence-based.
- Do not store secrets.
- Add `[MEMORY_UPDATED]` in final agent response after updating memory.

## Runtime artifacts
- `runtime/events.ndjson`: hook event trail (gitignored).
- `runtime/latest-hook-context.md`: latest lifecycle context snapshot (gitignored).
