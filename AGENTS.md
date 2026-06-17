# Homelab AI Agent Contract

This repository is configured for autonomous agents. Follow this contract in every run.

## Mission order
1. Complete the frontend roadmap in [docs/frontend-react-vite-ts-roadmap.md](docs/frontend-react-vite-ts-roadmap.md).
2. Then execute technical debt batches from section 5 in [docs/project-current-state-report.md](docs/project-current-state-report.md).
3. Preserve backend production stability while making changes.

## Non-negotiable rules
- Use the smallest safe change set.
- Never expose or print secrets from `.env` files.
- Keep Traefik + Cloudflare routing behavior intact unless a task explicitly asks for change.
- Prefer root-cause fixes over temporary patches.
- Validate each batch with the narrowest relevant checks first.
- **Be session-limit aware (Claude Max).** Check usage at session start, before any
  subagent fan-out, and between major tasks (`session-guard` MCP `get_usage` or
  `scripts/session-guard/check-usage.sh`). Reason adaptively (remaining session+week %,
  model in use, task size, fan-out — thresholds are advisory). If work can't finish within
  the window, persist state to `.ai/memory/active-context.md` and **auto-sleep until reset,
  then resume** (`wait_for_reset` / `wait-until-reset.sh` in background). Details in
  `CLAUDE.md` → "Session-limit awareness".
- **Hold all work to** `docs/architecture-principles.md` (microservices, scalability, K8s
  readiness, portability, test/validation); remediation phases in
  `docs/architecture-roadmap.md`.

## Required memory protocol
- Read these files before coding:
  - `.ai/memory/active-context.md`
  - `.ai/memory/decisions.md`
  - `.ai/memory/roadmap-status.md`
  - `.ai/memory/batch-status.md`
- After each completed task/batch:
  1. Update `.ai/memory/active-context.md`
  2. Add decisions to `.ai/memory/decisions.md`
  3. Update progress in `.ai/memory/roadmap-status.md` or `.ai/memory/batch-status.md`
  4. End with marker: `[MEMORY_UPDATED]`

## Agent execution pattern
- Use Plan-first for non-trivial work.
- Delegate targeted research to subagents when context grows.
- Prefer background agents for long-running, well-defined implementation batches.
- Use free Copilot-supported models from the model picker for autonomous runs.

## Safety gates
- Do not rotate or revoke secrets automatically unless explicitly requested.
- Do not run destructive commands (`rm -rf`, `docker system prune -a`, force-push).
- If uncertain, stop and ask one focused clarification.
