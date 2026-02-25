# Technical Debt Batch Status

Source: section 5 of `docs/project-current-state-report.md`

## P0
- Rotate exposed local tokens (security): NOT STARTED (manual-guided)
- Validate and fix `docker-compose.dev.yml` overrides: COMPLETED

## P1
- Introduce frontend toolchain + typed app structure: NOT STARTED
- Add frontend build/deploy process aligned with existing style: NOT STARTED

## P2
- Remove or isolate whoami services from production Traefik compose: COMPLETED
- Add minimal observability baseline: NOT STARTED

## Sequencing rule
Complete P0 before P1, and P1 before P2 unless explicitly overridden by user.
