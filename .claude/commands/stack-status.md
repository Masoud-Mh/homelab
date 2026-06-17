---
description: Show homelab-stack health — containers, endpoint health, git state
allowed-tools: Bash(docker ps:*), Bash(docker logs:*), Bash(curl:*), Bash(git status:*), Bash(git log:*), Bash(git branch:*)
---

Report the current state of the homelab-stack. Run these read-only checks and summarize concisely:

1. Containers: `docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}'` (expect traefik, cloudflared, site-frontend, site-backend).
2. Public health (don't fail the whole report if one errors):
   - `curl -fsS -o /dev/null -w '%{http_code}' https://masoud-mh.com/`
   - `curl -fsS https://api.masoud-mh.com/healthz`
3. Git: current branch, `git status -s`, and `git log --oneline -5`.

Then give a 3–5 line summary: are all containers up, are endpoints healthy, is the tree clean, and what branch are we on. Flag anything unexpected. Do NOT print secrets or full `.env` contents.
