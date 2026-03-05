# Frontend Deploy + Smoke Test Runbook

This runbook executes the current host-sync frontend rollout path.

## Preconditions
- Branch/ref to deploy is pushed to GitHub (for current work: `dev`).
- Self-hosted deploy runner is online with labels: `self-hosted`, `homelab`, `deploy`.
- Runner host has access to `/data/repos/homelab-stack` and writable `/srv/site/frontend/`.
- `npm` and `rsync` are available on runner host.

## Deploy (preferred: GitHub Actions)
Trigger workflow `.github/workflows/deploy-frontend.yml` with ref `dev`.

### Option A: GitHub UI
1. Open repository Actions tab.
2. Select workflow **deploy-frontend**.
3. Click **Run workflow**.
4. Set `ref` to `dev`.
5. Run and wait for successful completion.

### Option B: GitHub CLI
```bash
gh workflow run deploy-frontend.yml --ref dev -f ref=dev
```

## Deploy (fallback: run directly on host)
Run on the homelab host:

```bash
cd /data/repos/homelab-stack/app
./deploy-frontend.sh
```

Optional container restart if needed:

```bash
cd /data/repos/homelab-stack/app
RESTART_FRONTEND=true ./deploy-frontend.sh
```

## Smoke tests
Run from any machine with network access:

```bash
curl -fsS https://masoud-mh.com/ | head -n 20
curl -fsS https://www.masoud-mh.com/ | head -n 20
curl -fsS https://api.masoud-mh.com/healthz
```

Expected:
- Homepage responses are HTTP 200 and contain HTML.
- API health endpoint returns success payload.

## Browser checks
- Open `https://masoud-mh.com` and `https://www.masoud-mh.com`.
- Verify sections render: Projects, Skills, About, Contact.
- Verify API status badge transitions from checking to OK/degraded/unreachable.
- Verify in-page navigation links (`#projects`, `#skills`, `#about`, `#contact`).

## Rollback (host-sync)
On the deploy host, restore previous static bundle backup/snapshot if available, then re-sync to `/srv/site/frontend/`.

If no backup exists, re-run deploy using previous known-good git ref:

```bash
# GitHub Actions: run deploy-frontend with ref=<known-good-ref>
# or on host:
cd /data/repos/homelab-stack
git fetch --all --tags
git checkout <known-good-ref>
cd app
./deploy-frontend.sh
```
