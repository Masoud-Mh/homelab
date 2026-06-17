---
name: run-frontend-roadmap
description: Execute frontend roadmap phases with validation and memory updates
agent: homelab-implementer
argument-hint: Optional scope, e.g. "phase=1" or "phase=2.1"
---
Execute the frontend roadmap from [docs/frontend-react-vite-ts-roadmap.md](../../docs/frontend-react-vite-ts-roadmap.md).

Requirements:
- Respect current infra constraints and backend stability.
- Implement in small batches with validation after each batch.
- Use free Copilot-supported model selection.
- Update `.ai/memory/roadmap-status.md` and `.ai/memory/active-context.md`.
- End with `[MEMORY_UPDATED]`.

User input: ${input:scope:phase=1}
