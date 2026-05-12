#!/usr/bin/env bash
set -euo pipefail

CONTAINER_NAME="project-catalogue-cluster-control-plane"

# kill any running port-forwards
pkill -f "kubectl port-forward" 2>/dev/null || true

if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  echo "Not running."
  exit 0
fi

docker stop "${CONTAINER_NAME}"
echo "Stopped."

