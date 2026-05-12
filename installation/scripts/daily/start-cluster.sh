#!/usr/bin/env bash
set -euo pipefail

CONTAINER_NAME="project-catalogue-cluster-control-plane"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  echo "Container '${CONTAINER_NAME}' not found. Run 01-create-cluster.sh first."
  exit 1
fi

if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  docker start "${CONTAINER_NAME}"
  echo "Waiting for pods to stabilize..."
  sleep 10
fi

# kill stale port-forwards
pkill -f "kubectl port-forward" 2>/dev/null || true

exec "${SCRIPT_DIR}/port-forward.sh"

