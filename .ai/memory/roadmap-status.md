# Roadmap Status

## Architecture remediation — source: `docs/architecture-roadmap.md`
- Phase 0 (Session-limit awareness & governance): COMPLETED (2026-06-17)
- Phase 1 (De-hardcode host paths): DONE (2026-06-17) — SITE_ROOT/SITE_DEV_ROOT in compose + deploy-frontend.sh, vars.REPO_ROOT in deploy workflows; defaults unchanged, verified via `docker compose config`, infra-reviewer PASS, rsync-target guard added
- Phase 2 (Containerize frontend as OCI image): IN PROGRESS — Dockerfile + .dockerignore + frontend-ci image build/push (GHCR homelab-frontend) DONE & locally verified (2026-06-17); REMAINING: guarded compose cutover from host-mount to image after CI publishes from main
- Phase 3 (Vitest + pytest harness): TODO
- Phase 4 (K8s/Helm manifests): TODO — blocked on 1–3

## Frontend roadmap — source: `docs/frontend-react-vite-ts-roadmap.md`

- Phase 1 (Dev Foundation): COMPLETED
- Phase 2 (Production Delivery): COMPLETED (host-sync baseline)
- Phase 3 (Hardening): NOT STARTED

## Batch notes
- Use parity-first migration from static `index.html` into React components.
- Enforce `strict` and `strictNullChecks`.
- Use `VITE_API_BASE_URL` and `useEffect` cleanup for polling.

## Validation baseline
- `npm run build`
- `npm run preview`

## Implementation completion notes (2026-02-25)
- Created Vite React TS project structure under `app/frontend` with scripts: `dev`, `build`, `preview`, `typecheck`.
- Enforced strict TS compiler settings including `strict` and `strictNullChecks`.
- Migrated static content into parity sections: `AppShell`, `HeroSection`, `ProjectsSection`, `SkillsSection`, `AboutSection`, `ContactSection`, `ApiHealthBadge`.
- Added `.env.development` and `.env.production` with `VITE_API_BASE_URL` values.
- Added `app/deploy-frontend.sh` for `npm ci` + `npm run build` + `rsync --delete dist/ /srv/site/frontend/`.
- Added `.github/workflows/frontend-ci.yml` and `.github/workflows/deploy-frontend.yml`.
- Validated `npm run build` and `npm run preview` successfully in `app/frontend`.
