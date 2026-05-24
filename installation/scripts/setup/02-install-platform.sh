#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="project-catalogue-cluster"

if ! kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
  echo "Cluster '${CLUSTER_NAME}' not found. Run 01-create-cluster.sh first."
  exit 1
fi

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add argo https://argoproj.github.io/argo-helm
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

echo "Installing ingress-nginx..."
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --set controller.hostPort.enabled=true \
  --set controller.service.type=NodePort \
  --set controller.watchIngressWithoutClass=true \
  --wait --timeout 5m

echo "Installing argocd..."
helm upgrade --install argocd argo/argo-cd \
  --namespace argocd \
  --set server.service.type=ClusterIP \
  --set configs.params."server\.insecure"=true \
  --set configs.secret.argocdServerAdminPassword='$2a$10$EHq7yJQDxcwPnETVFsIM3.EBrn3D4lioW2mP1LjE5e.OLZbOeWjdi' \
  --wait --timeout 5m

echo "Installing kube-prometheus-stack..."
helm upgrade --install kube-prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set grafana.adminPassword=catalogue_admin \
  --set grafana.service.type=ClusterIP \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
  --set grafana.additionalDataSources[0].name=Loki \
  --set grafana.additionalDataSources[0].type=loki \
  --set grafana.additionalDataSources[0].url=http://loki.logging.svc.cluster.local:3100 \
  --set grafana.additionalDataSources[0].access=proxy \
  --set grafana.additionalDataSources[1].name=Tempo \
  --set grafana.additionalDataSources[1].type=tempo \
  --set grafana.additionalDataSources[1].url=http://tempo.monitoring.svc.cluster.local:3200 \
  --set grafana.additionalDataSources[1].access=proxy \
  --wait --timeout 5m

echo "Installing loki-stack..."
helm upgrade --install loki grafana/loki-stack \
  --namespace logging \
  --set loki.persistence.enabled=false \
  --set promtail.enabled=true \
  --set grafana.enabled=false \
  --wait --timeout 5m

echo "Installing tempo..."
helm upgrade --install tempo grafana/tempo \
  --namespace monitoring \
  --set tempo.storage.trace.backend=local \
  --set persistence.enabled=false \
  --wait --timeout 5m

echo "Installing postgresql..."
helm upgrade --install postgresql bitnami/postgresql \
  --namespace database \
  --set auth.postgresPassword=catalogue_postgres \
  --set primary.persistence.enabled=false \
  --set primary.initdb.scripts."init-databases\.sql"="
CREATE DATABASE dev_auth_db;
CREATE DATABASE dev_user_db;
CREATE DATABASE dev_project_db;
CREATE DATABASE prod_auth_db;
CREATE DATABASE prod_user_db;
CREATE DATABASE prod_project_db;
" \
  --wait --timeout 5m

echo "Done. Run 03-verify-platform.sh to check."

