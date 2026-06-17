# Architecture Remediation Roadmap

Phased plan to move the current state toward the standards in
[architecture-principles.md](architecture-principles.md). Each phase is sized to be
session-scoped and is sequenced behind the session-guard (so a phase that runs long
can auto-sleep through a limit reset and resume). Order is by leverage and risk.

Status legend: `TODO` · `IN PROGRESS` · `DONE`.

---

## Phase 0 — Session-limit awareness & governance — **DONE (2026-06-17)**

Built the session-guard system (`scripts/session-guard/`: usage substrate, auto-sleep
engine, hooks, MCP server, `/usage-check`) and these governance docs. This phase protects
every later phase. See `decisions.md` for the design record.

## Phase 1 — De-hardcode host paths (portability) — **TODO**  *(principle 4)*

**Why.** `/srv/site`, `/srv/site-dev`, `/data/repos/homelab-stack` are baked into compose,
deploy scripts, and workflows — the stack can't move hosts without edits everywhere.

**Touches.** `app/docker-compose.yml`, `app/docker-compose.dev.yml`,
`app/deploy-frontend.sh`, `app/deploy-backend.sh`, `.github/workflows/deploy-*.yml`,
new `app/.env.example` entries (`SITE_ROOT`, `SITE_DEV_ROOT`, `REPO_ROOT`).

**Approach.** Introduce env vars with defaults equal to today's values, so production
behavior is byte-for-byte unchanged. Parameterize, don't relocate.

**Done when.** `docker compose config` resolves with defaults; deploy scripts dry-run
against a temp `SITE_ROOT`; Traefik routers/services + cloudflared verified unchanged;
`curl https://api.masoud-mh.com/healthz` still green. Run `infra-reviewer` before PR.

## Phase 2 — Containerize the frontend as an OCI image — **DONE (2026-06-17)**  *(principles 1, 3, 4)*

**Image + CI:** multi-stage `app/frontend/Dockerfile` (node:22-alpine build →
nginx:alpine serving baked-in `dist/`, healthcheck) + `.dockerignore`; `frontend-ci`
extended with `image-pr-build` (no push) and `image-build-and-push` (GHCR
`homelab-frontend`, mirrors backend-ci). Published from `main`.

**Cutover (done):** `app/docker-compose.yml` frontend now runs
`image: ghcr.io/.../homelab-frontend:${FRONTEND_TAG:-latest}` (host mount kept as a
commented rollback); `deploy-frontend.sh` + `deploy-frontend.yml` rewritten to
pull+recreate by `FRONTEND_TAG`, mirroring the backend. Latent until a manual deploy.

**Defect caught & fixed during verify:** `.env.production`/`.env.development` were
gitignored (`.env.*`), so CI's clean checkout built the image WITHOUT
`VITE_API_BASE_URL` (host-sync only worked because it built on-server where the local
file existed). Since `VITE_*` is public client config, these files are now tracked (a
`.gitignore` negation; backend `.env*` stays ignored). Verified via a tracked-files-only
(CI-equivalent) build: image serves HTTP 200 with `https://api.masoud-mh.com` baked in.

<details><summary>Original phase scope</summary>

**Why.** nginx serves host-synced files (`deploy-frontend.sh` rsyncs `dist/` →
`/srv/site/frontend`). That host coupling is the main K8s blocker.

**Touches.** new `app/frontend/Dockerfile` (multi-stage build → nginx with baked-in
`dist/`), `backend-ci`-style GHCR push for the frontend, `app/docker-compose.yml`
(switch frontend from host mount to image).

**Approach.** Parity-first: build+push the image and verify it serves identically while
the host-sync path still works; flip compose to the image only after verification; keep
rollback to host-sync available.

**Done when.** `docker build app/frontend` succeeds; container serves the built site
locally; CI builds+pushes on the frontend path; routing parity verified before flip.

</details>

## Phase 3 — Test & validation harness — **DONE (2026-06-17)**  *(principle 5)*

Frontend: Vitest + @testing-library/react + jsdom; `AboutSection` smoke test;
`npm run test` wired into `frontend-ci` build job (test files excluded from the
production `tsc` gate). Backend: pytest + httpx `test_main.py` (`/` + `/healthz`
contracts); `requirements-dev.txt` (dev-only, out of the runtime image); `test` job
added to `backend-ci`. Verified locally: 1 frontend test + 2 backend tests pass; build
gate still green.

<details><summary>Original phase scope</summary>

**Why.** Only gate today is build/typecheck; no behavior is actually tested.

**Touches.** frontend: add Vitest + a smoke component test, wire into `frontend-ci`.
backend: add pytest with `/` + `/healthz` contract tests, wire into `backend-ci`.
optional: Trivy image scan in CI.

**Approach.** Additive — build/typecheck stays the floor; tests augment, don't replace.
No behavior change.

**Done when.** `npm run test` (Vitest) and `pytest` pass locally and in CI; build/typecheck
still green.

</details>

## Phase 4 — Kubernetes manifests / Helm — **TODO (P2 cutover + this remain)**  *(principles 2, 3)*

**Why.** Real K8s readiness once paths are parameterized, the frontend is an image, and
tests gate changes. (P1 ✅, P2 image ✅ / cutover pending, P3 ✅.)

**Touches.** new `k8s/` or a Helm chart: Deployments + Services + Ingress mapping the
current Traefik routes, ConfigMaps/Secrets for env, liveness/readiness probes.

**Approach.** Draft and validate against the routing contract first (document the mapping
from Traefik labels → Ingress). Do **not** implement until 1–3 are green.

**Done when.** Manifests render (`kubectl --dry-run` / `helm template`) and the
route/probe mapping is reviewed against today's Traefik config. (Live cluster deploy is
out of scope until a cluster exists.)

---

## Cross-cutting rules for every phase
- Branch off `dev`; smallest safe change set; parity before cutover.
- Preserve Traefik + Cloudflare routing and never expose secrets (hard guardrails).
- Validate with the narrowest relevant check, then routing integrity.
- Run the `infra-reviewer` subagent on any infra/compose/workflow/script change before PR.
- Update `.ai/memory/` and end with `[MEMORY_UPDATED]`.
