#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="project-catalogue-cluster"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KIND_CONFIG="${SCRIPT_DIR}/../../kind/kind-config.yaml"

NAMESPACES=(
  catalogue-dev
  catalogue-prod
  argocd
  monitoring
  logging
  ingress-nginx
  database
  messaging
)

if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
  echo "Cluster '${CLUSTER_NAME}' already exists. Skipping creation."
else
  echo "Creating Kind cluster '${CLUSTER_NAME}'..."
  kind create cluster --config "${KIND_CONFIG}"
  echo "Cluster created."
fi

echo "Creating namespaces..."
for ns in "${NAMESPACES[@]}"; do
  kubectl create namespace "${ns}" --dry-run=client -o yaml | kubectl apply -f -
done

echo ""
echo "Cluster '${CLUSTER_NAME}' is ready."
kubectl get namespaces

