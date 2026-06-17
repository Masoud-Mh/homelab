# Workspace AI Instructions

## Project scope
- Repository: Homelab stack with `infra/` and `app/` split.
- Primary near-term delivery:
  1. Frontend migration roadmap in [docs/frontend-react-vite-ts-roadmap.md](../docs/frontend-react-vite-ts-roadmap.md)
  2. Technical debt batches in section 5 of [docs/project-current-state-report.md](../docs/project-current-state-report.md)

## Coding priorities
- Keep changes surgical and production-safe.
- Preserve existing backend CI/CD behavior.
- Keep frontend rollout incremental (parity first, redesign later).
- Follow Vite/React/TS conventions:
  - Vite React TS scaffold and scripts (`build`, `preview`)
  - `VITE_` prefixed env variables
  - TypeScript strictness (`strict`, `strictNullChecks`)
  - React `useEffect` cleanup for polling side effects

## Infrastructure priorities
- Respect current Traefik routing and hostnames.
- Do not leak secrets or include credential values in output.
- Treat token rotation as guided/manual unless user explicitly requests direct execution.

## Execution expectations
- For multi-step work: create plan, implement, validate, summarize.
- Use subagents for narrow research/synthesis when task context is large.
- Prefer background agents for autonomous implementation batches.
- Use free models supported in GitHub Copilot subscription for automatic runs.

## Memory requirements
- Always load and update memory files under `.ai/memory/`.
- Before finishing, write outcomes into memory files and include `[MEMORY_UPDATED]`.
