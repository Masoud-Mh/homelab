# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A production-style homelab stack hosting a personal portfolio site. Public traffic flows:

```
Internet → Cloudflare Edge (DNS/TLS/WAF) → Cloudflare Tunnel (cloudflared, outbound-only)
         → Traefik (hostname routing) → Docker services (frontend nginx + backend FastAPI)
```

No inbound ports are opened on the router; TLS terminates at Cloudflare. The repo is split into `app/` (the deployed application) and `infra/` (Traefik, cloudflared, self-hosted Actions runner). Production runs on a homelab server at `/data/repos/homelab-stack` (this same path), so the working directory **is** the deploy target — be careful with anything that touches running containers or `/srv/site/`.

## Architecture notes that span files

- **Routing is label-driven, not config-file-driven.** Traefik discovers routes from `traefik.http.*` labels on each service in `app/docker-compose.yml`, not from `infra/traefik/config/traefik.yml` (which only holds static/platform config). To change hostnames or ports, edit the compose labels. Traefik only exposes containers with `traefik.enable=true` on the external `traefik_proxy` network.
- **The frontend container serves prebuilt static files, it does not build them.** `app/docker-compose.yml` runs stock `nginx:alpine` mounting `/srv/site/frontend` (read-only). The React/Vite app in `app/frontend/` is built by `deploy-frontend.sh`, which runs `npm run build` and `rsync`s `dist/` into `/srv/site/frontend/`. So a code change in `app/frontend/src/` has no effect until that build+sync runs.
- **Backend is deployed as a prebuilt image, not built on the server.** `app/docker-compose.yml` pulls `ghcr.io/masoud-mh/homelab-backend:${BACKEND_TAG}`. CI (`backend-ci`) builds and pushes the image to GHCR; the server only pulls. The commented-out `build:` block is intentionally inactive.
- **Frontend → backend API base URL is build-time, not runtime.** `ApiHealthBadge` reads `import.meta.env.VITE_API_BASE_URL`, baked in at build by `.env.production` (`https://api.masoud-mh.com`) / `.env.development` (`http://localhost:8081`). Changing the API host means rebuilding the frontend.
- **Backend CORS is env-driven.** `app/backend/main.py` reads a comma-separated `CORS_ORIGINS` from the environment (via `app/.env`). The FastAPI app is intentionally tiny — `/` and `/healthz` only.

## Commands

### Frontend (run from `app/frontend/`)
```bash
npm install          # first-time setup
npm run dev          # Vite dev server
npm run build        # tsc --noEmit (typecheck) THEN vite build — build fails on type errors
npm run typecheck    # type check only
npm run preview      # serve the production build locally
```
There is no test runner or linter configured; `npm run build` (with its embedded `tsc`) is the only validation gate, and it's exactly what `frontend-ci` runs on PRs.

### Deploy (these mutate the live server — run only when intended)
```bash
cd app && ./deploy-frontend.sh                       # npm ci + build + rsync dist → /srv/site/frontend
cd app && BACKEND_TAG=sha-xxxx ./deploy-backend.sh    # pull image from GHCR + recreate backend container
```
Normally deploys run via GitHub Actions `workflow_dispatch` (`deploy-frontend` / `deploy-backend`) on the self-hosted runner, not by hand.

### Running the stack locally
```bash
cd infra/traefik   && sudo docker compose up -d
cd app             && sudo docker compose up -d      # prod-like (needs external traefik_proxy network + /srv/site mounts)
cd infra/cloudflared && sudo docker compose up -d
```
For dev without Traefik, layer the override (binds ports 8080/8081, disables Traefik labels):
```bash
cd app && docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d
```

### Health / debugging
```bash
sudo docker ps
sudo docker logs traefik|cloudflared|site-backend-1 --tail 100
curl https://api.masoud-mh.com/healthz
```

## CI/CD

- `frontend-ci` — PR/push on `app/frontend/**`: runs `npm ci && npm run build` (validation only).
- `backend-ci` — PR builds image without pushing; push to `main`/tags builds and pushes to GHCR (`latest` only on main, plus `sha-<sha>` and ref-based tags).
- `deploy-backend` / `deploy-frontend` — manual `workflow_dispatch`, run on `[self-hosted, homelab, deploy]`, `cd /data/repos/homelab-stack/app` and invoke the deploy scripts.

## Conventions and guardrails

These come from `AGENTS.md` and `.github/copilot-instructions.md` and apply to all changes here:

- **Preserve Traefik + Cloudflare routing** unless a task explicitly asks to change it. Routing being intact is a hard requirement.
- **Never print or expose secrets** from `.env` files (cloudflared tunnel token, etc.). Treat token rotation as manual/guided.
- Keep changes surgical and production-safe; frontend rollout is incremental (parity first, redesign later).
- TypeScript runs strict; clean up `useEffect` side effects (see the polling/abort pattern in `ApiHealthBadge.tsx`). Env vars consumed by the frontend must be `VITE_`-prefixed.
- Avoid destructive commands (`rm -rf`, `docker system prune -a`, force-push).

## AI memory system

This repo carries its own cross-session memory under `.ai/memory/` (separate from Claude Code's own memory). A SessionStart/Stop/PreCompact/SubagentStop hook (`.github/hooks/ai-memory.json` → `scripts/ai-memory/run-memory-hook.sh`) writes runtime context there. When doing substantial autonomous work, read `.ai/memory/active-context.md`, `decisions.md`, `roadmap-status.md`, and `batch-status.md` first, and update them when done. `runtime/` artifacts are gitignored.

The current work program (per `AGENTS.md`): (1) the frontend React/Vite/TS roadmap in `docs/frontend-react-vite-ts-roadmap.md`, then (2) technical-debt batches in section 5 of `docs/project-current-state-report.md`.

## Claude Code ownership setup

Claude Code is the primary maintainer. Project-scoped Claude Code config lives in `.claude/`:

- **Subagents** (`.claude/agents/`): `deploy-operator` (deploy + smoke flow, careful with live containers/`/srv/site`), `infra-reviewer` (reviews `infra/**`, `docker-compose*.yml`, `*.sh`, `workflows/**` for routing integrity + secret safety), `frontend-dev` (scoped `app/frontend/**`, strict-TS/`VITE_`/effect-cleanup conventions).
- **Slash commands** (`.claude/commands/`): `/stack-status`, `/deploy-frontend [ref]`, `/deploy-backend [tag]`, `/smoke-test`, `/sync-memory`.
- **Memory bridge**: `.ai/memory/` stays the canonical git-tracked state. A SessionStart hook in `.claude/settings.json` runs `scripts/ai-memory/run-memory-hook.sh` so that context auto-loads. Durable facts are mirrored into Claude Code's native memory; `/sync-memory` keeps both current (ending with the `[MEMORY_UPDATED]` marker).
- **Runbooks**: `docs/frontend-deploy-smoke-runbook.md` (deploy + smoke), `docs/credential-rotation-runbook.md` (P0 token rotation — manual).

The legacy Copilot-era setup (`.github/agents`, `.github/instructions`, `.github/prompts`, `.github/copilot-instructions.md`) is retained for reference.
