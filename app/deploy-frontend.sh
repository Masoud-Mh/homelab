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

echo "Syncing dist to /srv/site/frontend/..."
rsync -av --delete dist/ /srv/site/frontend/

if [[ "${RESTART_FRONTEND:-false}" == "true" ]]; then
  echo "Restarting frontend container..."
  cd ..
  docker compose restart frontend
fi

echo "Done."