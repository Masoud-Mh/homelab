# Active Context

## Current objective
Operate session-limit-aware and migrate the stack toward the architecture principles
(`docs/architecture-principles.md`). Session-guard system + governance: DONE (2026-06-17).
Next: architecture remediation roadmap (`docs/architecture-roadmap.md`), then resume the
frontend roadmap / section-5 debt batches.

Prior objective (still standing): implement frontend roadmap (React + Vite + TypeScript)
in parity-first mode. (PHASE 1 + PHASE 2 BASELINE COMPLETED)

## In-progress focus
- Frontend migrated from static `app/frontend/index.html` to React component structure in `app/frontend/src/components`.
- Vite + React + TypeScript toolchain added with strict TS and env-based API URL.
- API health polling implemented with `useEffect` cleanup and interval management.
- Frontend deployment path added via `app/deploy-frontend.sh` (host-sync to `/srv/site/frontend`).
- Frontend CI and manual CD workflows added in `.github/workflows/frontend-ci.yml` and `.github/workflows/deploy-frontend.yml`.
- Follow-up TS diagnostics fix applied: `main.tsx` now uses named imports, and `tsconfig.node.json` handles `vite.config.ts` resolution.
- Added deploy execution runbook: `docs/frontend-deploy-smoke-runbook.md` for workflow trigger, smoke checks, and rollback path.

## Next actions
1. Architecture roadmap Phase 1: de-hardcode host paths (`SITE_ROOT`/`REPO_ROOT` env, defaults unchanged) — see `docs/architecture-roadmap.md`.
2. Phase 2: containerize frontend as an OCI image (parity-first, GHCR push) — also satisfies the long-deferred image-based frontend delivery batch.
3. Phase 3: add Vitest (frontend) + pytest (backend) and wire into CI.
4. Rotate exposed local tokens manually (P0 security, still manual-guided).
5. Continue section-5 technical debt batches.

NOTE: each action is session-limit aware — check usage before fan-out; auto-sleep through a reset if needed (see CLAUDE.md "Session-limit awareness").

## Ownership
Primary developer/maintainer is now Claude Code (handoff from GitHub Copilot, 2026-06-17).
Claude Code config in `.claude/` (agents, commands, settings hook). Native memory mirror at
`~/.claude/projects/-data-repos-homelab-stack/memory/`; this `.ai/memory/` stays canonical.

## Last updated
2026-06-17
