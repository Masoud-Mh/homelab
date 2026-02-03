#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.yml"

if [ ! -f "$COMPOSE_FILE" ]; then
  echo "Missing docker-compose.yml in $SCRIPT_DIR"
  exit 1
fi

if [ ! -f "$SCRIPT_DIR/.env" ]; then
  echo "Missing .env file in $SCRIPT_DIR"
  echo "Create it from .env.example and set RUNNER_TOKEN to the remove token."
  exit 1
fi

set -a
# shellcheck source=/dev/null
source "$SCRIPT_DIR/.env"
set +a

if [ -z "${RUNNER_REMOVE_TOKEN:-}" ]; then
  echo "RUNNER_REMOVE_TOKEN is not set in .env"
  echo "Set RUNNER_REMOVE_TOKEN to the remove token from: Repo Settings > Actions > Runners > New self-hosted runner (remove token)"
  exit 1
fi

TOKEN="$RUNNER_REMOVE_TOKEN"

echo "Stopping runner container..."
sudo docker compose -f "$COMPOSE_FILE" down

echo "Starting container temporarily to access config..."
sudo docker compose -f "$COMPOSE_FILE" up -d

echo "Removing runner registration via config.sh remove..."
sudo docker exec -it github-actions-runner bash -lc "./config.sh remove --token \"$TOKEN\""

echo "Stopping and removing volumes..."
sudo docker compose -f "$COMPOSE_FILE" down -v

echo "Done."
