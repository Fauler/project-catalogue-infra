#!/usr/bin/env bash
set -euo pipefail

for ns in ingress-nginx argocd monitoring logging database catalogue-dev catalogue-prod; do
  echo "--- ${ns} ---"
  kubectl get pods -n "${ns}" 2>/dev/null || echo "(empty)"
  echo ""
done

echo "--- argocd admin password ---"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d && echo "" || echo "(not found)"

echo ""
echo "--- postgresql databases ---"
POSTGRES_POD=$(kubectl get pods -n database -l app.kubernetes.io/name=postgresql -o jsonpath="{.items[0].metadata.name}" 2>/dev/null)
if [ -n "${POSTGRES_POD}" ]; then
  kubectl exec -n database "${POSTGRES_POD}" -- env PGPASSWORD=catalogue_postgres psql -U postgres -c "\l" 2>/dev/null || echo "(could not connect)"
else
  echo "(no pod found)"
fi
