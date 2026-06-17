---
description: Deploy the frontend via GitHub Actions (preferred) then smoke-test
argument-hint: "[ref, default: dev]"
---

Deploy the homelab-stack frontend. Ref to deploy: ${1:-dev}.

Delegate to the `deploy-operator` subagent. Steps:
1. Confirm the working tree / target ref is what we intend to ship (`git status`, current branch). The frontend is built+synced from this ref — source edits are inert until this runs.
2. Preferred: trigger GitHub Actions —
   `gh workflow run deploy-frontend.yml --ref ${1:-dev} -f ref=${1:-dev}` — then `gh run watch` the resulting run.
   - If `gh` is not authenticated, stop and tell me to run `gh auth login`; offer the on-host fallback `cd app && ./deploy-frontend.sh` only if I approve.
3. After success, run the smoke tests from `docs/frontend-deploy-smoke-runbook.md` and report endpoint results + container health.

Guardrails: preserve routing, never print secrets, no destructive commands, confirm before any on-host mutation.
