#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="project-catalogue-cluster"
APP_REPO_PATH="${1:-../project-catalogue}"
INFRA_DIR="$(cd "$(dirname "$0")/../.." && pwd)"

if ! kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
  echo "Cluster '${CLUSTER_NAME}' not found. Run 01-create-cluster.sh first."
  exit 1
fi

if [ ! -d "$APP_REPO_PATH" ]; then
  echo "App repo not found at '$APP_REPO_PATH'. Pass the path as first argument."
  echo "Usage: $0 /path/to/project-catalogue [github-token]"
  exit 1
fi

echo "Building Docker images..."
docker build -t project-catalogue-auth-service:latest -f "$APP_REPO_PATH/infrastructure/docker/auth-service/Dockerfile" "$APP_REPO_PATH"
docker build -t project-catalogue-user-service:latest -f "$APP_REPO_PATH/infrastructure/docker/user-service/Dockerfile" "$APP_REPO_PATH"
docker build -t project-catalogue-project-service:latest -f "$APP_REPO_PATH/infrastructure/docker/project-service/Dockerfile" "$APP_REPO_PATH"

echo "Loading images into Kind cluster..."
kind load docker-image project-catalogue-auth-service:latest --name "$CLUSTER_NAME"
kind load docker-image project-catalogue-user-service:latest --name "$CLUSTER_NAME"
kind load docker-image project-catalogue-project-service:latest --name "$CLUSTER_NAME"

GITHUB_TOKEN="${2:-}"
if [ -n "$GITHUB_TOKEN" ]; then
  echo "Registering private repo in ArgoCD..."
  kubectl create secret generic repo-project-catalogue-kubernetes \
    --namespace argocd \
    --from-literal=type=git \
    --from-literal=url=https://github.com/Fauler/project-catalogue-kubernetes.git \
    --from-literal=username=Fauler \
    --from-literal=password="$GITHUB_TOKEN" \
    -o yaml --dry-run=client | kubectl label --local -f - argocd.argoproj.io/secret-type=repository -o yaml | kubectl apply -f -
fi

echo "Applying ArgoCD manifests..."
kubectl apply -f "$INFRA_DIR/argocd/project-catalogue-project.yaml"
kubectl apply -f "$INFRA_DIR/argocd/deploy-dev.yaml"
kubectl apply -f "$INFRA_DIR/argocd/deploy-prod.yaml"

echo "Done. Check ArgoCD at http://localhost:19880"

