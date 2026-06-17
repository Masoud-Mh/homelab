---
name: run-techdebt-batches
description: Execute section 5 technical debt batches in priority order
agent: homelab-implementer
argument-hint: Optional scope, e.g. "batch=P0" or "batch=P1"
---
Implement section 5 from [docs/project-current-state-report.md](../../docs/project-current-state-report.md), priority order P0 -> P1 -> P2.

Rules:
- Keep secrets hidden and avoid printing sensitive values.
- Validate each batch before moving on.
- Keep backend deployment path stable.
- Use free Copilot-supported models for autonomous execution.
- Update `.ai/memory/batch-status.md`, `.ai/memory/decisions.md`, and `.ai/memory/active-context.md`.
- End with `[MEMORY_UPDATED]`.

User input: ${input:scope:batch=P0}
