# Homelab Stack — Current State Report

Date: 2026-02-25  
Scope: Full repository scan (all readable files in workspace, including local `.env` files; excluding `.git` internals).  
Note: `app/backend/__pycache__/main.cpython-312.pyc` is binary and not human-readable by text reader.

---

## 1) Executive Summary

The project is a working homelab platform with:
- Edge exposure via Cloudflare Tunnel (`cloudflared`)
- Internal reverse proxy + host-based routing via Traefik v3
- FastAPI backend deployed as immutable GHCR image
- Static frontend served by Nginx container using host-mounted files
- CI for backend build/push and manual CD via self-hosted GitHub runner

Operational maturity is **good for a single-service backend pipeline**, with clear infra/application split. Frontend delivery is currently **manual/static** (no frontend CI/CD pipeline yet).

---

## 2) Repository + Runtime Layout (Observed)

## Root
- `.gitignore`: broad secret protections (`**/.env`, `*.env`, `**/*token*`, `**/*secret*`, etc.)
- `README.md`: architecture and operational documentation
- `.env`: local Cloudflare tunnel token placeholder in root

## Application (`app/`)
- `docker-compose.yml` (production-oriented):
  - `frontend`: `nginx:alpine`, host bind `/srv/site/frontend:/usr/share/nginx/html:ro`, Traefik labels for `site.local`, `masoud-mh.com`, `www.masoud-mh.com`
  - `backend`: image `ghcr.io/masoud-mh/homelab-backend:${BACKEND_TAG}`, Traefik labels for `api.site.local`, `api.masoud-mh.com`, env from `app/.env`
  - external network `traefik_proxy`
- `docker-compose.dev.yml` (override-style file, not standalone)
  - disables Traefik labels and maps ports (`8080`, `8081`)
  - points backend env to `.env.dev`
  - includes a likely misplaced frontend volume under backend service
- `deploy-backend.sh`:
  - requires `BACKEND_TAG`
  - pulls backend image, recreates only backend service, prunes images
  - sets `COMPOSE_PROJECT_NAME=site`
- `app/.env`: CORS origins for backend
- `app/.env.dev`: includes `ENVIRONMENT=dev`, `CORS_ORIGINS`, `BACKEND_TAG=latest`
- `app/.env.example`: example CORS config

### Backend (`app/backend/`)
- `main.py`: FastAPI app with:
  - `/` root message
  - `/healthz` health endpoint
  - CORS from `CORS_ORIGINS` comma-separated env var
- `requirements.txt`: `fastapi==0.128.0`, `uvicorn[standard]==0.40.0`
- `Dockerfile`:
  - base `python:3.12.12-slim-bookworm`
  - installs deps, copies `main.py`, exposes `8000`
  - includes container healthcheck against `/healthz`

### Frontend (`app/frontend/`)
- single `index.html` portfolio page
- inline CSS + JS
- JS polls `https://api.masoud-mh.com/healthz` every 30s when tab visible
- no npm-based toolchain currently

## Infrastructure (`infra/`)

### Traefik (`infra/traefik/`)
- `docker-compose.yml`:
  - `traefik:v3.6.7`, port `80:80`
  - docker provider (`exposedByDefault=false` in static config)
  - dashboard router for `traefik.local` or `traefik.masoud-mh.com`
  - BasicAuth middleware from `TRAEFIK_DASHBOARD_USERS`
  - includes demo `whoami` services
  - network `traefik_proxy`
- `config/traefik.yml`:
  - dashboard enabled
  - `web` entrypoint on `:80`
  - access logs enabled
- `.env`: dashboard htpasswd credential present

### Cloudflared (`infra/cloudflared/`)
- `docker-compose.yml`:
  - `cloudflare/cloudflared:2026.1.2`
  - command: `tunnel --no-autoupdate run --token ${CLOUDFLARE_TUNNEL_TOKEN}`
  - attached to external `traefik_proxy`
- `.env.example`: token placeholder
- `.env`: active token present

### GitHub Action Runner (`infra/github_action_runner/`)
- `Dockerfile`:
  - Ubuntu 22.04
  - installs Docker CLI + runner dependencies
  - downloads actions runner `v2.331.0`
  - configurable `DOCKER_GID`
- `docker-compose.yml`:
  - builds runner image
  - mounts docker socket
  - mounts `app/.env` into checked-out workspace path in container
  - uses named volume for runner config persistence
- `README.md`: setup/run/remove instructions
- `remove-runner.sh`: explicit deregistration flow using `RUNNER_REMOVE_TOKEN`
- `.env.example`: template
- `.env`: registration + remove tokens present

## GitHub Actions (`.github/workflows/`)
- `backend-ci.yml`:
  - PR: build-only (no push)
  - trusted events (push/tags/manual): build + push to GHCR
  - tags include branch/tag/sha and `latest` on main
- `deploy-backend.yml`:
  - manual dispatch with optional `backend_tag`
  - runs on self-hosted labels `[self-hosted, homelab, deploy]`
  - logs in GHCR, resolves tag to `inputs.backend_tag` or `sha-${GITHUB_SHA}`
  - executes `app/deploy-backend.sh`

---

## 3) Security & Secret Hygiene (Current)

Observed risk level: **high (local secret exposure in workspace)**
- Active Cloudflare tunnel token found in `infra/cloudflared/.env`
- Active runner tokens found in `infra/github_action_runner/.env`
- Traefik dashboard hash credential exists in `infra/traefik/.env`

Even if gitignored, these are still sensitive in any shared filesystem/session. Recommended immediate actions:
1. Rotate Cloudflare tunnel token
2. Rotate runner registration/remove tokens
3. Regenerate dashboard credential if exposure risk exists
4. Keep secrets in host secret store or CI secret manager where feasible

---

## 4) Operational Status Assessment

Strengths:
- Clear routing model and domain mapping
- Backend image immutability + reproducible CI pipeline
- Controlled manual production deploy path
- Health checks present at app and container levels

Current limitations:
- Frontend is static/manual (no React/Vite pipeline yet)
- Dev compose file appears incomplete/misaligned as standalone usage
- Traefik stack includes demo `whoami` services in production stack
- Cloudflare token passed via CLI arg (visible in process metadata contexts)

---

## 5) Immediate Technical Debt / Cleanup Targets

Priority P0:
- Rotate exposed local tokens (security)
- Validate and fix `docker-compose.dev.yml` overrides

Priority P1:
- Introduce frontend toolchain + typed app structure (React + Vite + TS)
- Add frontend build/deploy process aligned with existing GHCR + manual deploy style

Priority P2:
- Remove or isolate `whoami` services from production Traefik compose
- Add minimal observability baseline (structured logs + container-level metrics)

---

## 6) Read-Completeness Log

Human-readable files reviewed:
- Root: `README.md`, `.gitignore`, `.env`
- Workflows: `backend-ci.yml`, `deploy-backend.yml`
- App: `docker-compose.yml`, `docker-compose.dev.yml`, `deploy-backend.sh`, `.env`, `.env.dev`, `.env.example`
- Backend: `Dockerfile`, `requirements.txt`, `main.py`
- Frontend: `index.html`
- Infra/Traefik: `docker-compose.yml`, `config/traefik.yml`, `.env`
- Infra/Cloudflared: `docker-compose.yml`, `.env.example`, `.env`
- Infra/Runner: `docker-compose.yml`, `Dockerfile`, `README.md`, `.env.example`, `.env`, `remove-runner.sh`

Non-text/binary file discovered:
- `app/backend/__pycache__/main.cpython-312.pyc` (not parseable as text)
