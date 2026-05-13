#!/usr/bin/env bash
set -euo pipefail

kubectl port-forward svc/argocd-server -n argocd 19880:80 &
kubectl port-forward svc/kube-prometheus-grafana -n monitoring 19000:80 &
kubectl port-forward svc/kube-prometheus-kube-prome-prometheus -n monitoring 19090:9090 &
kubectl port-forward svc/kube-prometheus-kube-prome-alertmanager -n monitoring 19093:9093 &
kubectl port-forward svc/postgresql -n database 19432:5432 &

kubectl port-forward svc/auth-service-dev -n catalogue-dev 19083:8083 &
kubectl port-forward svc/user-service-dev -n catalogue-dev 19081:8081 &
kubectl port-forward svc/project-service-dev -n catalogue-dev 19082:8082 &

kubectl port-forward svc/auth-service-prod -n catalogue-prod 19183:8083 &
kubectl port-forward svc/user-service-prod -n catalogue-prod 19181:8081 &
kubectl port-forward svc/project-service-prod -n catalogue-prod 19182:8082 &

echo "=== Platform ==="
echo "ArgoCD:       http://localhost:19880  (admin/catalogue_admin)"
echo "Grafana:      http://localhost:19000  (admin/catalogue_admin)"
echo "Prometheus:   http://localhost:19090"
echo "Alertmanager: http://localhost:19093"
echo "Loki:         via Grafana (Explore > Loki datasource)"
echo "PostgreSQL:   localhost:19432  (postgres/catalogue_postgres)"
echo ""
echo "=== Services (Dev) ==="
echo "Auth:    http://localhost:19083"
echo "User:    http://localhost:19081"
echo "Project: http://localhost:19082"
echo ""
echo "=== Services (Prod) ==="
echo "Auth:    http://localhost:19183"
echo "User:    http://localhost:19181"
echo "Project: http://localhost:19182"
echo ""
echo "Ctrl+C to stop."

wait

