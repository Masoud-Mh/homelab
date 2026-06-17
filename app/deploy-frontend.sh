#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

echo "Deploying frontend..."
echo "Current time: $(date -Is)"

cd frontend

echo "Installing dependencies..."
npm ci

echo "Building frontend..."
npm run build

SITE_ROOT="${SITE_ROOT:-/srv/site}"
# Guard the rsync --delete target: refuse to prune a non-existent root.
if [[ ! -d "$SITE_ROOT" ]]; then
  echo "ERROR: SITE_ROOT '$SITE_ROOT' is not a directory; refusing to rsync --delete." >&2
  exit 1
fi
echo "Syncing dist to ${SITE_ROOT}/frontend/..."
mkdir -p "${SITE_ROOT}/frontend"
rsync -av --delete dist/ "${SITE_ROOT}/frontend/"

if [[ "${RESTART_FRONTEND:-false}" == "true" ]]; then
  echo "Restarting frontend container..."
  cd ..
  docker compose restart frontend
fi

echo "Done."