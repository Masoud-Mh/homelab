#!/usr/bin/env bash
set -euo pipefail

# Always run from the directory this script lives in
cd "$(dirname "$0")"

COMPOSE_PROJECT_NAME=site
export COMPOSE_PROJECT_NAME

echo "Deploying backend..."
echo "Current time: $(date -Is)"

# Pull the image referenced by compose (uses BACKEND_TAG if set, otherwise latest)
echo "Pulling backend image..."
docker compose pull backend

# Recreate backend container using the newly pulled image
echo "Restarting backend container..."
docker compose up -d --no-deps --force-recreate backend

# Optional: cleanup old images (safe; removes unused layers)
echo "Pruning unused images..."
docker image prune -f

echo "Done."
