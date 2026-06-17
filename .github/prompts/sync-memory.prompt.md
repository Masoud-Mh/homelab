---
name: sync-memory
description: Refresh project memory files after coding sessions
agent: homelab-memory-curator
---
Refresh `.ai/memory/` based on the current workspace state and latest completed tasks.

Required updates:
- `.ai/memory/active-context.md`
- `.ai/memory/decisions.md`
- one of: `.ai/memory/roadmap-status.md` or `.ai/memory/batch-status.md`

Constraints:
- Keep summaries concise and factual.
- Remove stale completed-next-step mismatches.
- End with `[MEMORY_UPDATED]`.
