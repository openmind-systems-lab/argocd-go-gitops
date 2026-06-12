# Argo CD Go GitOps Demo

This repository demonstrates a complete GitOps workflow using Argo CD, Kubernetes, and a containerized Go application.

The project showcases how to manage Kubernetes deployments declaratively with Git as the single source of truth. Changes committed to the repository are automatically synchronized to the cluster by Argo CD, enabling reproducible, auditable, and automated application delivery.

## What is included

- `app/`: Go HTTP service with `/` and `/healthz`
- `Dockerfile`: multi-stage container build
- `manifests/`: Kubernetes namespace, deployment, service, and Kustomize file
- `argocd-apps/`: Argo CD `Application` manifest
- `.github/workflows/`: optional GitHub Actions workflow to publish the image to GHCR
- `scripts/`: helper scripts

## Prerequisites

For local deployment on Docker Desktop Kubernetes, install:

- Docker Desktop with Kubernetes enabled
- `kubectl`
- Go, only if you want to run the app locally without Docker
- GitHub account or another Git server where Argo CD can read this repository

Check that Docker Desktop Kubernetes is your active cluster:

```bash
kubectl config current-context
kubectl get nodes
```

For Docker Desktop, the context is usually:

```bash
kubectl config use-context docker-desktop
```

## Run the Go app locally

```bash
go run ./app
curl http://localhost:8080/
curl http://localhost:8080/healthz
```

## Build and push the image

Argo CD deploys from Kubernetes manifests. Kubernetes must be able to pull your container image, so push it to a registry such as GHCR or Docker Hub.

Edit the image name first in:

- `manifests/deployment.yaml`
- `scripts/build-and-push.sh`, or pass `IMAGE=...`

Example using GitHub Container Registry:

```bash
IMAGE=ghcr.io/YOUR_GITHUB_USER/argocd-go-gitops:1.0.0 ./scripts/build-and-push.sh
```

Then update `manifests/deployment.yaml` with the same image:

```yaml
image: ghcr.io/YOUR_GITHUB_USER/argocd-go-gitops:1.0.0
```

Commit and push the repository to GitHub before creating the Argo CD application:

```bash
git add .
git commit -m "Initial Go GitOps demo"
git branch -M main
git remote add origin https://github.com/YOUR_GITHUB_USER/argocd-go-gitops.git
git push -u origin main
```

## Install Argo CD on Docker Desktop Kubernetes

Create the Argo CD namespace:

```bash
kubectl create namespace argocd
```

Install Argo CD using the official manifests:

```bash
kubectl apply -n argocd --server-side --force-conflicts \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

Wait for the Argo CD pods to become ready:

```bash
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
kubectl wait --for=condition=available --timeout=300s deployment/argocd-repo-server -n argocd
kubectl wait --for=condition=available --timeout=300s deployment/argocd-redis -n argocd
kubectl wait --for=condition=available --timeout=300s deployment/argocd-applicationset-controller -n argocd
```

You can also inspect everything with:

```bash
kubectl get pods -n argocd
kubectl get svc -n argocd
```

## Open the Argo CD UI locally

In a separate terminal, port-forward the Argo CD server:

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Open:

```text
https://localhost:8080
```

Your browser may warn about a self-signed certificate. For a local Docker Desktop setup, you can proceed.

Get the initial admin password:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d; echo
```

Login with:

```text
username: admin
password: <password from the command above>
```

## Configure the Argo CD application

Edit `argocd-apps/go-demo-application.yaml` and replace this value:

```yaml
repoURL: https://github.com/your-org/argocd-go-gitops.git
```

with your real repository URL, for example:

```yaml
repoURL: https://github.com/YOUR_GITHUB_USER/argocd-go-gitops.git
```

Then apply the Argo CD application to your Docker Desktop cluster:

```bash
kubectl apply -f argocd-apps/go-demo-application.yaml
```

Argo CD will sync the manifests from the `manifests/` folder, create the `go-demo` namespace, deploy the app, prune removed resources, and self-heal drift.

Check the application:

```bash
kubectl -n argocd get applications
kubectl -n go-demo get pods
kubectl -n go-demo get svc
```

## Test the deployed Go app

Port-forward the application service:

```bash
kubectl -n go-demo port-forward svc/go-demo 8081:80
```

Then test it:

```bash
curl http://localhost:8081/
curl http://localhost:8081/healthz
```

The app runs on port `8080` inside the container, but the Kubernetes service exposes it on port `80`. The local port-forward above maps your machine's `8081` to the service's `80`.

## Optional: install the Argo CD CLI

The UI is enough for this demo, but the CLI is useful.

macOS:

```bash
brew install argocd
```

Windows with Chocolatey:

```powershell
choco install argocd-cli
```

Linux:

```bash
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64
```

CLI login while the port-forward is running:

```bash
argocd login localhost:8080 --username admin --password <PASSWORD> --insecure
argocd app list
argocd app get go-demo
```

## Troubleshooting

### `the server could not find the requested resource` when applying the Argo CD app

Argo CD is probably not installed yet, or its CRDs are not ready. Wait a bit and try again:

```bash
kubectl get crd | grep argoproj
kubectl apply -f argocd-apps/go-demo-application.yaml
```

### Argo CD cannot pull the Git repository

Make sure the repository URL in `argocd-apps/go-demo-application.yaml` is correct and reachable from Argo CD. Public repositories work without extra configuration. Private repositories require adding Git credentials in Argo CD.

### Kubernetes cannot pull the image

Make sure the image in `manifests/deployment.yaml` exists and is public, or configure an image pull secret.

Check the pod events:

```bash
kubectl -n go-demo describe pod <POD_NAME>
```

### Port 8080 is already used

Use another local port for Argo CD:

```bash
kubectl port-forward svc/argocd-server -n argocd 9090:443
```

Then open:

```text
https://localhost:9090
```

## Clean up

Delete the demo application and namespace:

```bash
kubectl delete -f argocd-apps/go-demo-application.yaml
kubectl delete namespace go-demo
```

Delete Argo CD:

```bash
kubectl delete namespace argocd
```

## Important values to change

Search for these placeholders and replace them:

- `your-org`
- `YOUR_GITHUB_USER`
- `ghcr.io/YOUR_GITHUB_USER/argocd-go-gitops:1.0.0`
