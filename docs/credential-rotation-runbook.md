# Secret Rotation Runbook

Rotation procedure for the local secrets the current-state report flags as **P0**. These
values live in gitignored `.env` files on the homelab host (never committed). This runbook
documents the steps; **execute it yourself** — Claude will not rotate live secrets.

> Guardrails: never paste real tokens into chat, commits, or memory. Only `.env.example`
> files (placeholders) are tracked in git. After any rotation, confirm the affected service
> is healthy before moving on.

## Secrets in scope

| Secret | File | Variable |
|--------|------|----------|
| Cloudflare Tunnel token | `infra/cloudflared/.env` | `CLOUDFLARE_TUNNEL_TOKEN` |
| Runner registration token | `infra/github_action_runner/.env` | `RUNNER_TOKEN` |
| Runner remove token | `infra/github_action_runner/.env` | `RUNNER_REMOVE_TOKEN` (only when removing) |
| Traefik dashboard BasicAuth | `infra/traefik/.env` | `TRAEFIK_DASHBOARD_USERS` |

---

## 1. Cloudflare Tunnel token

1. Cloudflare dashboard → **Zero Trust → Networks → Tunnels** → select the tunnel.
2. **Refresh / rotate** the token (or delete + recreate the connector token). Copy the new token.
3. On the host, edit `infra/cloudflared/.env` and set `CLOUDFLARE_TUNNEL_TOKEN=<new token>`.
4. Recreate the connector:
   ```bash
   cd /data/repos/homelab-stack/infra/cloudflared
   sudo docker compose up -d --force-recreate
   sudo docker logs cloudflared --tail 30   # expect "Registered tunnel connection"
   ```
5. Smoke: `curl -fsS https://masoud-mh.com/` returns 200.

## 2. Traefik dashboard credentials

`TRAEFIK_DASHBOARD_USERS` is an Apache-format `user:bcrypt-hash` string (no plaintext).

1. Generate a new hash (htpasswd, or `docker run --rm httpd:alpine htpasswd -nbB <user> '<newpass>'`).
2. Edit `infra/traefik/.env` → `TRAEFIK_DASHBOARD_USERS=<user>:<hash>`.
   - Note: there is no `infra/traefik/.env.example`; consider adding one with a placeholder
     so the variable is documented for future setup.
3. Recreate Traefik (this also re-creates the `traefik_proxy` network; downstream services
   rejoin automatically):
   ```bash
   cd /data/repos/homelab-stack/infra/traefik
   sudo docker compose up -d --force-recreate
   ```
4. Verify dashboard auth prompts with the new credentials at `https://traefik.masoud-mh.com/dashboard/`.

## 3. Self-hosted runner tokens

Runner registration tokens are short-lived; rotation usually means re-registering.

1. **Remove the old runner** (uses a one-time *remove* token):
   - GitHub repo → **Settings → Actions → Runners** → the runner → get a **remove token**.
   - Put it in `infra/github_action_runner/.env` as `RUNNER_REMOVE_TOKEN=<token>`.
   - Run:
     ```bash
     cd /data/repos/homelab-stack/infra/github_action_runner
     ./remove-runner.sh    # down → config.sh remove → down -v
     ```
2. **Re-register**: get a fresh **registration token** (same Runners page → *New self-hosted runner*).
   Set `RUNNER_TOKEN=<token>` (and confirm `GITHUB_REPO_URL=https://github.com/Masoud-Mh/homelab`) in `.env`.
3. Start it:
   ```bash
   sudo docker compose up -d
   sudo docker logs github-actions-runner --tail 30   # expect "Listening for Jobs"
   ```
4. Confirm labels `self-hosted, homelab, deploy` show online in the repo Runners page, then
   clear `RUNNER_REMOVE_TOKEN` from `.env`.

---

## After rotating

- Confirm the public site, API health, and Traefik dashboard all respond.
- A deploy-workflow dry run (`gh workflow run deploy-frontend.yml --ref dev -f ref=dev`)
  confirms the runner is healthy end-to-end.
- Update `.ai/memory/batch-status.md` (P0 token rotation) and `.ai/memory/active-context.md`
  to reflect completion.
