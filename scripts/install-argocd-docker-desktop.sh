#!/usr/bin/env bash
set -euo pipefail

CONTEXT="${CONTEXT:-docker-desktop}"
ARGOCD_NAMESPACE="${ARGOCD_NAMESPACE:-argocd}"
ARGOCD_INSTALL_URL="${ARGOCD_INSTALL_URL:-https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml}"

echo "Switching kubectl context to: ${CONTEXT}"
kubectl config use-context "${CONTEXT}"

echo "Creating namespace: ${ARGOCD_NAMESPACE}"
kubectl create namespace "${ARGOCD_NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

echo "Installing Argo CD..."
kubectl apply -n "${ARGOCD_NAMESPACE}" --server-side --force-conflicts -f "${ARGOCD_INSTALL_URL}"

echo "Waiting for core Argo CD deployments..."
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n "${ARGOCD_NAMESPACE}"
kubectl wait --for=condition=available --timeout=300s deployment/argocd-repo-server -n "${ARGOCD_NAMESPACE}"
kubectl wait --for=condition=available --timeout=300s deployment/argocd-redis -n "${ARGOCD_NAMESPACE}"
kubectl wait --for=condition=available --timeout=300s deployment/argocd-applicationset-controller -n "${ARGOCD_NAMESPACE}"

echo
echo "Argo CD is installed. Start the UI with:"
echo "  kubectl port-forward svc/argocd-server -n ${ARGOCD_NAMESPACE} 8080:443"
echo
echo "Initial admin password:"
kubectl -n "${ARGOCD_NAMESPACE}" get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
