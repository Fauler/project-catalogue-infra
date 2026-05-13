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
helm repo add elastic https://helm.elastic.co
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
  --wait --timeout 5m

echo "Installing elasticsearch..."
helm upgrade --install elasticsearch elastic/elasticsearch \
  --namespace logging \
  --set replicas=1 \
  --set minimumMasterNodes=1 \
  --set resources.requests.memory=512Mi \
  --set resources.limits.memory=1Gi \
  --set resources.requests.cpu=250m \
  --set persistence.enabled=false \
  --set esJavaOpts="-Xmx384m -Xms384m" \
  --set antiAffinity=soft \
  --set protocol=http \
  --set extraEnvs[0].name=xpack.security.enabled \
  --set extraEnvs[0].value=false \
  --wait --timeout 5m

echo "Installing kibana..."
helm upgrade --install kibana elastic/kibana \
  --namespace logging \
  --set service.type=ClusterIP \
  --set resources.requests.memory=256Mi \
  --set resources.limits.memory=512Mi \
  --set resources.requests.cpu=250m \
  --set elasticsearchHosts=http://elasticsearch-master:9200 \
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

