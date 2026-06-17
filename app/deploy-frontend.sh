#!/usr/bin/env bash
set -euo pipefail

# Always run from the directory this script lives in
cd "$(dirname "$0")"

: "${FRONTEND_TAG:?FRONTEND_TAG is required (e.g. sha-xxxx, latest)}"

export COMPOSE_PROJECT_NAME=site

echo "Deploying frontend (image-based)..."
echo "Current time: $(date -Is)"
echo "Target image: ghcr.io/masoud-mh/homelab-frontend:${FRONTEND_TAG}"

# Pull the image referenced by compose (uses FRONTEND_TAG).
echo "Pulling frontend image..."
docker compose pull frontend

# Recreate the frontend container using the newly pulled image.
echo "Recreating frontend container..."
docker compose up -d --no-deps --force-recreate frontend

# Cleanup old images (safe; removes unused layers).
echo "Pruning unused images..."
docker image prune -f

echo "Done."

# ----------------------------------------------------------------------------
# ROLLBACK (legacy host-sync deploy): if you revert app/docker-compose.yml to the
# host-mount model (nginx:alpine + ${SITE_ROOT}/frontend mount), use this instead:
#
#   cd frontend
#   npm ci
#   npm run build
#   SITE_ROOT="${SITE_ROOT:-/srv/site}"
#   [[ -d "$SITE_ROOT" ]] || { echo "SITE_ROOT '$SITE_ROOT' not a dir" >&2; exit 1; }
#   mkdir -p "${SITE_ROOT}/frontend"
#   rsync -av --delete dist/ "${SITE_ROOT}/frontend/"
#   [[ "${RESTART_FRONTEND:-false}" == "true" ]] && { cd ..; docker compose restart frontend; }
# ----------------------------------------------------------------------------
