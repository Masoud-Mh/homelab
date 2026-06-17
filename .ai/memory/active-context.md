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

## Architecture roadmap — ALL PHASES MERGED TO main (2026-06-17)
P0 session-guard+governance, P1 de-hardcode paths, P2 frontend OCI image + cutover,
P3 Vitest+pytest, P4 k8s draft — all merged (PRs #3, #4, #5). main == dev. CI publishes
homelab-frontend + homelab-backend images to GHCR.

## Next actions
1. **Activate the frontend image cutover when ready** (it is LATENT — live site still runs the old host-mount container). Trigger the `deploy-frontend` workflow (workflow_dispatch) with a `FRONTEND_TAG` (e.g. `latest` or a `sha-<sha>`); it pulls the image + recreates the container. Smoke-test after (`/smoke-test`). Rollback = revert compose to the commented host-mount + redeploy.
2. P4 k8s/ is a DRAFT (not deployed; no cluster). Pre-deploy needs in `k8s/README.md`.
3. Rotate exposed local tokens manually (P0 security, still manual-guided).
4. Continue section-5 technical debt batches.

NOTE: each action is session-limit aware — check usage before fan-out; auto-sleep through a reset if needed (see CLAUDE.md "Session-limit awareness"). Reminder: ccusage proxy over-reads near a block boundary; trust authoritative `claude -p /usage` (this session: proxy flagged defer at 92% while authoritative was 14%).

## Ownership
Primary developer/maintainer is now Claude Code (handoff from GitHub Copilot, 2026-06-17).
Claude Code config in `.claude/` (agents, commands, settings hook). Native memory mirror at
`~/.claude/projects/-data-repos-homelab-stack/memory/`; this `.ai/memory/` stays canonical.

## Last updated
2026-06-17
