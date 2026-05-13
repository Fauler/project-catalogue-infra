#!/usr/bin/env bash
set -euo pipefail

APP_REPO_PATH="${1:-../project-catalogue}"
CLUSTER_NAME="project-catalogue-cluster"
SERVICE="auth-service"
IMAGE="project-catalogue-${SERVICE}:latest"

if [ ! -d "$APP_REPO_PATH" ]; then
  echo "App repo not found at '$APP_REPO_PATH'. Pass the path as first argument."
  exit 1
fi

echo "Building ${SERVICE}..."
docker build -t "$IMAGE" -f "$APP_REPO_PATH/infrastructure/docker/${SERVICE}/Dockerfile" "$APP_REPO_PATH"

echo "Loading into cluster..."
kind load docker-image "$IMAGE" --name "$CLUSTER_NAME"

echo "Restarting pods..."
kubectl rollout restart deployment ${SERVICE}-dev -n catalogue-dev
kubectl rollout restart deployment ${SERVICE}-prod -n catalogue-prod

echo "${SERVICE} reloaded."

