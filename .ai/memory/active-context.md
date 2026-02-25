# Active Context

## Current objective
Implement frontend roadmap (React + Vite + TypeScript) in parity-first mode. (PHASE 1 + PHASE 2 BASELINE COMPLETED)

## In-progress focus
- Frontend migrated from static `app/frontend/index.html` to React component structure in `app/frontend/src/components`.
- Vite + React + TypeScript toolchain added with strict TS and env-based API URL.
- API health polling implemented with `useEffect` cleanup and interval management.
- Frontend deployment path added via `app/deploy-frontend.sh` (host-sync to `/srv/site/frontend`).
- Frontend CI and manual CD workflows added in `.github/workflows/frontend-ci.yml` and `.github/workflows/deploy-frontend.yml`.
- Follow-up TS diagnostics fix applied: `main.tsx` now uses named imports, and `tsconfig.node.json` handles `vite.config.ts` resolution.

## Next actions
1. Rotate exposed local tokens manually (P0 security, still manual-guided).
2. Run live deploy dry-run/production deploy via manual frontend workflow.
3. After stable rollout, execute containerized/image-based frontend delivery batch.
4. Continue technical debt batches from section 5 after frontend stabilization.

## Last updated
2026-02-25
