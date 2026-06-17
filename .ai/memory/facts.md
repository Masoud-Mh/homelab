# Stable Facts

- Stack split: `infra/` (Traefik, Cloudflared, runner), `app/` (frontend, backend).
- Backend: FastAPI served from GHCR image, manual deploy workflow exists.
- Frontend: currently static files served by Nginx from `/srv/site/frontend`.
- Public routing: Cloudflare Tunnel -> Traefik -> app services.
- Frontend migration target: React + Vite + TypeScript with strict typing.
- Technical debt source of truth: section 5 in `docs/project-current-state-report.md`.

Guardrails:
- Keep backend CI/CD behavior stable.
- Keep routing and hostnames stable unless explicitly requested.
- Never expose secrets in outputs or memory.
