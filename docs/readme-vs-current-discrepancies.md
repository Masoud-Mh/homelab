# README vs Current Project State — Discrepancy Report

Date: 2026-02-25  
Compared files: `README.md` vs actual repository/runtime files in workspace.

---

## High-Impact Discrepancies

## 1) Frontend source of truth is unclear
README implies frontend is in `app/frontend/index.html`, but production compose serves frontend from host path:
- `app/docker-compose.yml` mounts `/srv/site/frontend` into Nginx

Impact:
- Editing `app/frontend/index.html` does **not automatically** change production output unless content is synced to `/srv/site/frontend`.

Recommendation:
- Document explicit sync/deploy path for frontend assets (or move to image-based frontend deployment).

## 2) Local run instructions can fail without `BACKEND_TAG`
README “How to Run” says `cd app && docker compose up -d`, but backend image is:
- `ghcr.io/masoud-mh/homelab-backend:${BACKEND_TAG}`

If `BACKEND_TAG` is not set in environment or compose substitution context, startup may fail.

Recommendation:
- Add required setup step (e.g., `export BACKEND_TAG=latest` or include default in compose).

## 3) Dashboard protection mechanism mismatch (or under-documented)
README says Traefik dashboard is Access-protected (Cloudflare Access), but infra also enforces Traefik BasicAuth via:
- `TRAEFIK_DASHBOARD_USERS` in `infra/traefik/.env`

Impact:
- Actual auth model is dual/stacked or differs from README wording.

Recommendation:
- Clarify whether BasicAuth is fallback, temporary, or intended permanent layer.

---

## Medium-Impact Discrepancies

## 4) `docker-compose.dev.yml` behavior is not documented and appears inconsistent
README does not document dev compose usage; file appears to be an override file, not a full standalone compose.
Also includes likely misplaced volume in backend service:
- `/srv/site-dev/frontend:/usr/share/nginx/html:ro` under `backend`

Impact:
- Dev startup flow is ambiguous and potentially broken.

Recommendation:
- Document exact command (`docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d`) and fix backend volume mapping.

## 5) Production infra includes demo services not mentioned
Traefik compose includes `whoami` and `whoami_alt` demo containers.

Impact:
- Increases attack surface/noise in production-like stack.

Recommendation:
- Move demos to a dedicated sandbox compose file or remove.

## 6) Deploy default-tag semantics are slightly ambiguous
README says empty input deploys “latest main commit.” Workflow resolves to `sha-${GITHUB_SHA}` for that workflow run.

Impact:
- Usually aligned on default branch dispatch, but wording could mislead in edge cases.

Recommendation:
- Adjust README language to: “defaults to the commit SHA of the workflow run context.”

---

## Low-Impact Documentation Drift

## 7) Repository tree in README is incomplete vs current workspace
Current workspace also contains:
- `app/docker-compose.dev.yml`
- `app/.env.example`
- local `.env` files under `app/`, `infra/traefik/`, `infra/cloudflared/`, `infra/github_action_runner/`

Impact:
- Minor drift; mostly expected for local secrets.

Recommendation:
- Keep tracked-tree section current and optionally add note that local `.env` files are intentionally omitted.

---

## Security-Sensitive Observations Not Reflected in README

README correctly says secrets are never committed, but local runtime files currently contain active tokens/credentials in workspace:
- Cloudflare tunnel token
- Runner registration/remove tokens
- Dashboard BasicAuth hash

Recommendation:
- Add an operational security note: rotate tokens after accidental exposure and prefer short-lived or centrally managed secrets.

---

## Summary

The README is broadly accurate at architectural level. Main corrective areas are:
1. Frontend deployment source of truth
2. `BACKEND_TAG` requirement for app startup
3. Dev compose usage clarity
4. Explicit auth model for Traefik dashboard
5. Cleanup/documentation of demo services and deploy tag semantics
