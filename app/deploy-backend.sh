#!/usr/bin/env bash
set -euo pipefail

# Always run from the directory this script lives in
cd "$(dirname "$0")"

: "${BACKEND_TAG:?BACKEND_TAG is required (e.g. sha-xxxx, v0.1.0)}"


export COMPOSE_PROJECT_NAME=site

echo "Deploying backend..."
echo "Current time: $(date -Is)"
echo "Target image: ghcr.io/masoud-mh/homelab-backend:${BACKEND_TAG}"


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
