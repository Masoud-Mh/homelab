# Frontend Roadmap Status

Source: `docs/frontend-react-vite-ts-roadmap.md`

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
