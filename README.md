# learning-repo — DevOps / Platform Engineer project

This repo is a small end-to-end demo:
- A tiny Node/TypeScript API
- Containerized with Docker
- Deployed to a local Kubernetes cluster (kind) using Helm
- AWS infrastructure bootstrapped with Terraform (remote state + ECR)
- CI builds and pushes immutable images to ECR using GitHub Actions + OIDC (no long-lived AWS keys)
- Ansible automates deploys by refreshing the ECR pull secret (token-based) and deploying the latest `sha-*` image via Helm

The goal: **code → build → publish → deploy → verify**.

---

## Repo structure

- `app/` — Node/TypeScript API
- `deploy/helm/learning-api/` — Helm chart to deploy the API
- `infra/terraform/` — Terraform for AWS resources (remote state + ECR + GitHub OIDC role)
- `ansible/` — Ansible playbooks to deploy + refresh ECR auth in the cluster
- `scripts/` — helper scripts for deploy workflows

---

## Prereqs

Local tooling:
- Docker Desktop
- `kubectl`
- `kind`
- `helm`
- Node.js + npm (for local dev)
- Python 3 (for Ansible)

AWS (for ECR + Terraform):
- AWS CLI configured
- Terraform installed

---

## Local quick start

### 1) Build and run locally (Docker)

```bash
docker build -t learning-api:local ./app
docker run --rm -p 3000:3000 learning-api:local
curl http://localhost:3000/healthz
```

### 2) Create local Kubernetes cluster (kind)

```bash
kind create cluster --name learning
kubectl get nodes
```

### 3) Deploy with Helm (kind)

```bash
helm install learning-api ./deploy/helm/learning-api -n demo --create-namespace
kubectl rollout status deployment/learning-api -n demo

kubectl port-forward svc/learning-api -n demo 3000:3000
curl http://localhost:3000/healthz
```

---

## CI: GitHub Actions → ECR (immutable tags)

On pushes to `main`, GitHub Actions:
- builds TypeScript
- builds a Docker image
- pushes to ECR with an immutable tag: `sha-<commit>`

This uses GitHub OIDC to assume an AWS role (no AWS keys stored in GitHub).

---

## Deploy automation (Ansible)

### Deploy latest image from ECR to the cluster

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install ansible

ansible-playbook -c local -i ansible/inventory/hosts.ini ansible/playbooks/deploy_latest.yml
```

What it does:
1) fetches a fresh ECR login token
2) updates the Kubernetes `imagePullSecret` used to pull from ECR
3) finds the newest `sha-*` tag in ECR
4) runs `helm upgrade` to deploy that image
5) waits for rollout and prints the running image/digest

---

## Helpful scripts 
Deploy a specific SHA (pinpoint / rollback):
```bash
./scripts/deploy.sh <git-sha>
```

Deploy the newest `sha-*` tag currently in ECR:
```bash
./scripts/deploy-latest.sh
```

---