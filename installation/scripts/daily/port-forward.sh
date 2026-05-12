#!/usr/bin/env bash
set -euo pipefail

kubectl port-forward svc/argocd-server -n argocd 19880:80 &
kubectl port-forward svc/kube-prometheus-grafana -n monitoring 19000:80 &
kubectl port-forward svc/kibana-kibana -n logging 19601:5601 &
kubectl port-forward svc/postgresql -n database 19432:5432 &

echo "ArgoCD:     http://localhost:19880"
echo "Grafana:    http://localhost:19000  (admin/catalogue_admin)"
echo "Kibana:     http://localhost:19601"
echo "PostgreSQL: localhost:19432  (postgres/catalogue_postgres)"
echo ""
echo "Ctrl+C to stop."

wait

