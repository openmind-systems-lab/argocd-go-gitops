#!/usr/bin/env bash
set -euo pipefail

IMAGE=${IMAGE:-ghcr.io/your-org/argocd-go-gitops:1.0.0}

docker build -t "$IMAGE" .
docker push "$IMAGE"

echo "Pushed $IMAGE"
