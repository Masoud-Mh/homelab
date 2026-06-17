---
description: Update project memory (.ai/memory canonical + Claude-native mirror)
---

Update the project's memory to reflect the work done this session.

1. **Canonical, git-tracked** — update the relevant files in `.ai/memory/`:
   - `active-context.md` (current objective, in-progress focus, next actions, last-updated date)
   - `roadmap-status.md` / `batch-status.md` (mark phases/batches done/in-progress)
   - `decisions.md` (append notable decisions with rationale)
   - `facts.md` only if a stable fact changed.
   Keep entries compact and actionable; remove stale lines. Use today's absolute date.
2. **Claude-native mirror** — if a DURABLE fact changed (architecture, deploy model, guardrails, ownership, env), update the matching file under `/home/masoud/.claude/projects/-data-repos-homelab-stack/memory/` and its `MEMORY.md` index. Do NOT mirror fast-moving status there — point to `.ai/memory` instead.
3. End your response with the literal marker `[MEMORY_UPDATED]` (the repo's Stop hook checks for it).

Do not commit unless I ask. Never write secrets into memory.
