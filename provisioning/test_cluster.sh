#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

KCONF="${STATE_DIR}/kubeconfig"
[[ -f "$KCONF" ]] || die "kubeconfig missing — run get_kubeconfig.sh"
command -v kubectl >/dev/null 2>&1 || die "kubectl not installed — run prep_host.sh"

export KUBECONFIG="${KCONF}"

log "cluster-info"
kubectl cluster-info
echo
log "nodes"
kubectl get nodes -o wide
echo
log "system pods"
kubectl get pods -A
echo
log "cilium status"
kubectl -n kube-system get pods -l k8s-app=cilium -o wide || true
kubectl -n kube-system get pods -l app.kubernetes.io/name=hubble-relay -o wide 2>/dev/null || true
