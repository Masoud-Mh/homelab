---
description: Run the post-deploy smoke tests from the runbook
allowed-tools: Bash(curl:*), Bash(docker ps:*), Bash(docker logs:*)
---

Run the smoke tests defined in `docs/frontend-deploy-smoke-runbook.md` and report results.

1. `curl -fsS https://masoud-mh.com/ | head -n 20` — expect HTTP 200 + HTML.
2. `curl -fsS https://www.masoud-mh.com/ | head -n 20` — expect HTTP 200 + HTML.
3. `curl -fsS https://api.masoud-mh.com/healthz` — expect a success payload (`{"status":"ok"}`).
4. Container health: `docker ps` (traefik, cloudflared, frontend, backend all healthy/up).

Summarize pass/fail per check. If a check fails, surface the error and suggest the likely cause (deploy not run, container down, routing). Note that browser-only checks (section rendering, API badge transition, in-page nav) still need a manual visit to https://masoud-mh.com. Do NOT print secrets.
