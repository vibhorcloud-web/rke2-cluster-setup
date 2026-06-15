#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

KCONF="${STATE_DIR}/kubeconfig"
[[ -f "$KCONF" ]] || die "kubeconfig missing — run get_kubeconfig.sh"
export KUBECONFIG="${KCONF}"

log "Installing ArgoCD into the cluster..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

log "Waiting for ArgoCD deployments to be ready (this may take a couple of minutes)..."
# We wait for the argocd-server deployment to be fully available
kubectl wait --for=condition=Available deployment/argocd-server -n argocd --timeout=300s

log "Applying App of Apps bootstrap manifest..."
# This points ArgoCD to look at the repo and start syncing the other apps.
kubectl apply -f "${LAB_ROOT}/argo-apps/bootstrap/app-of-apps.yaml"

ok "ArgoCD and GitOps sync initiated successfully."
