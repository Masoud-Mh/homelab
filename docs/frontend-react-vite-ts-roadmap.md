# Frontend Roadmap — React + Vite + TypeScript

Date: 2026-02-25  
Goal: Evolve current static frontend to a maintainable React+Vite+TypeScript app, aligned with existing homelab architecture and deployment style.

Context7 basis used:
- Vite (`/vitejs/vite`): `npm create vite@latest ... -- --template react-ts`, `npm run build`, `npm run preview`, default build output `dist/`
- React (`/reactjs/react.dev`): componentized architecture and correct `useEffect` usage for side effects with cleanup
- TypeScript (`/microsoft/typescript`): strict compiler settings (`strict: true`, `strictNullChecks`)

---

## Current Constraints to Respect

- Public routing remains via Traefik + Cloudflare Tunnel.
- Current frontend runtime is `nginx:alpine` serving static files from host path `/srv/site/frontend`.
- Backend remains FastAPI at `api.masoud-mh.com` with CORS configured by env.
- Existing backend CI/CD should remain stable while frontend rollout is introduced incrementally.

---

## Phase 1 — Development Foundation (React+Vite+TS)

## 1.1 Scaffold and baseline
From `app/` create frontend project using Vite React TS template:

```bash
npm create vite@latest frontend -- --template react-ts
cd frontend
npm install
```

Expected scripts:
- `npm run dev`
- `npm run build`
- `npm run preview`

## 1.2 TypeScript quality gates
Set strict typing in `tsconfig`:
- `"strict": true`
- `"strictNullChecks": true`

Add checks to workflow-local commands:
```bash
npm run build
```
(Optionally add explicit `typecheck` script via `tsc --noEmit`.)

## 1.3 Migration strategy from current `index.html`
Move current single-page content into React components:
- `AppShell` (nav/footer/layout)
- `HeroSection`
- `ProjectsSection`
- `SkillsSection`
- `AboutSection`
- `ContactSection`
- `ApiHealthBadge`

Keep behavior parity first (no redesign yet).

## 1.4 API integration and environment handling
Use Vite env variables:
- `.env.development`: `VITE_API_BASE_URL=http://localhost:8081`
- `.env.production`: `VITE_API_BASE_URL=https://api.masoud-mh.com`

Use `fetch(`${import.meta.env.VITE_API_BASE_URL}/healthz`)` in `ApiHealthBadge` with `useEffect` cleanup and poll interval.

## 1.5 Local development workflow
Run backend in dev mode and frontend via Vite:
- Backend: compose stack (prefer documented override flow)
- Frontend: `npm run dev -- --host 0.0.0.0 --port 5173`

Acceptance criteria:
- Static page feature parity achieved in React app
- Health indicator works in local and prod env modes
- `npm run build` and `npm run preview` succeed

---

## Phase 2 — Production Delivery (Aligned with Current Stack)

## 2.1 Keep current serving model first (lowest-risk)
Continue serving static assets via existing Nginx container + host mount:
- Build artifacts from Vite output in `app/frontend/dist`
- Sync `dist/` contents to `/srv/site/frontend`

Suggested deploy script (new):
- `app/deploy-frontend.sh`
  1. `cd app/frontend`
  2. `npm ci`
  3. `npm run build`
  4. `rsync -av --delete dist/ /srv/site/frontend/`
  5. optional: `docker compose restart frontend`

## 2.2 Add frontend CI validation
Create workflow (new) for frontend checks on PR + main:
- install deps
- run build (and lint/typecheck if added)
- optional artifact upload of `dist/`

## 2.3 Add frontend deployment workflow (manual first)
Mirror backend deployment pattern:
- `workflow_dispatch` with optional ref input
- run on self-hosted runner
- execute `app/deploy-frontend.sh`

This keeps operational model consistent and auditable.

## 2.4 Domain/routing compatibility
No Traefik changes needed if output path remains `/srv/site/frontend` and existing router labels stay unchanged.

Acceptance criteria:
- Deploying frontend does not interrupt backend service
- `https://masoud-mh.com` and `https://www.masoud-mh.com` serve React build
- Client-side navigation works (if router added, ensure SPA fallback handling in Nginx)

---

## Phase 3 — Hardening and Improvements

- Add `eslint` + formatting rules
- Add lightweight component/unit tests (Vitest + Testing Library)
- Add bundle size budget checks
- Add frontend rollback strategy (timestamped build backups under `/srv/site/frontend`)
- Optionally migrate to image-based frontend deployment later for immutable frontend artifacts

---

## Suggested Implementation Order (Practical)

1. Scaffold Vite React TS in `app/frontend` (or `app/frontend-react` if preserving old files during migration)
2. Migrate static sections with visual parity
3. Wire env-based API URL + health check polling
4. Validate local dev (`npm run dev`) and prod build (`npm run build`, `npm run preview`)
5. Add `deploy-frontend.sh` to sync `dist/` to `/srv/site/frontend`
6. Add frontend CI, then manual frontend CD workflow
7. Remove legacy static-only implementation after stable rollout

---

## Risks and Mitigations

- Risk: CORS mismatch during local Vite dev  
  Mitigation: include `http://localhost:5173` (or chosen dev origin) in backend `CORS_ORIGINS` for dev.

- Risk: Incomplete dev compose docs  
  Mitigation: document exact compose command order and env setup.

- Risk: Secret leakage in runner/local env files  
  Mitigation: rotate tokens and avoid exposing tokens in logs/scripts.

---

## Definition of Done

The frontend migration is “done” when:
- React+Vite+TS frontend is default served app
- Builds are reproducible and validated in CI
- Production deploy is scripted and auditable on self-hosted runner
- Existing domains and backend integration continue working without manual patching
