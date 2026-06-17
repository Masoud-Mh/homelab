---
description: Deploy the backend image via GitHub Actions then verify
argument-hint: "[backend_tag, e.g. sha-xxxx or latest]"
---

Deploy the homelab-stack backend. Target tag: ${1:-(resolve from latest main CI)}.

Delegate to the `deploy-operator` subagent. Steps:
1. Resolve the image tag to deploy. If I didn't pass one, list recent `backend-ci` runs / GHCR tags via `gh` and propose the newest `sha-<sha>` (or `latest` on main). Confirm with me before deploying.
2. Preferred: `gh workflow run deploy-backend.yml -f backend_tag=<tag>` then `gh run watch`.
   - If `gh` isn't authenticated, stop and tell me to run `gh auth login`; offer the on-host fallback `cd app && BACKEND_TAG=<tag> ./deploy-backend.sh` only if I approve.
3. Verify: `curl -fsS https://api.masoud-mh.com/healthz`, confirm the running container image matches the deployed tag (`docker ps`), and check `docker logs site-backend-1 --tail 50`.

Guardrails: preserve routing, never print secrets, no destructive commands beyond the script's own `docker image prune -f`.
