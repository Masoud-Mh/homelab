---
name: Infra Tech Debt Batch Rules
description: Apply when changing infra, compose, workflows, or deploy scripts
applyTo: "{infra/**,app/docker-compose*.yml,app/*.sh,.github/workflows/**,docs/**}"
---
# Technical debt batch rules
- Execute section 5 priorities in [docs/project-current-state-report.md](../../docs/project-current-state-report.md) in P0 → P1 → P2 order.
- P0 security work must avoid exposing current secret values in logs or comments.
- Keep backend deployment path stable (`deploy-backend.yml` + `app/deploy-backend.sh`).
- For dev compose fixes, keep production compose untouched unless strictly required.
- For frontend CI/CD additions, mirror backend workflow style for consistency.
- Record each completed batch in `.ai/memory/batch-status.md` and `.ai/memory/decisions.md`.
