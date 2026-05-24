# project-catalogue-infra

Kind cluster bootstrap and platform setup for the project-catalogue ecosystem.

Application charts and deploys live in `project-catalogue-kubernetes`.

## Prerequisites

- Docker
- [Kind](https://kind.sigs.k8s.io/) — `brew install kind`
- kubectl — `brew install kubectl`
- Helm — `brew install helm`

## First-time setup

```bash
./installation/scripts/setup/01-create-cluster.sh
./installation/scripts/setup/02-install-platform.sh
./installation/scripts/setup/03-verify-platform.sh
./installation/scripts/setup/04-deploy-apps.sh /path/to/project-catalogue
```

## Day-to-day

```bash
./installation/scripts/daily/start-cluster.sh
./installation/scripts/daily/stop-cluster.sh
```

⚠️ `start-cluster.sh` also sets up all port-forwards — without it, nothing is accessible from localhost.

### Reload after code changes

```bash
./installation/scripts/daily/reload-auth-service.sh /path/to/project-catalogue
./installation/scripts/daily/reload-user-service.sh /path/to/project-catalogue
./installation/scripts/daily/reload-project-service.sh /path/to/project-catalogue
```

Rebuilds the Docker image, loads it into Kind, and restarts the pods (dev + prod).

## Teardown

```bash
./installation/scripts/setup/00-delete-cluster.sh
```

## What gets installed

| Component          | URL / Host              | Credentials                                                                 |
|--------------------|-------------------------|-----------------------------------------------------------------------------|
| Ingress NGINX      | localhost:19080 / :19443| —                                                                           |
| ArgoCD             | http://localhost:19880  | `admin` / `catalogue_admin`                                                 |
| Grafana            | http://localhost:19000  | `admin` / `catalogue_admin`                                                 |
| Prometheus         | http://localhost:19090  | —                                                                           |
| Alertmanager       | http://localhost:19093  | —                                                                           |
| Loki               | via Grafana (Explore)   | —                                                                           |
| PostgreSQL         | localhost:19432         | `postgres` / `catalogue_postgres`                                           |

PostgreSQL databases: `dev_auth_db`, `dev_user_db`, `dev_project_db`, `prod_auth_db`, `prod_user_db`, `prod_project_db`

Namespaces: `catalogue-dev`, `catalogue-prod`, `argocd`, `monitoring`, `logging`, `ingress-nginx`, `database`
