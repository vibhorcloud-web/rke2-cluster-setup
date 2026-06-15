#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

for entry in "${VM_LIST[@]}"; do
  read -r name cpus mem disk role <<<"$entry"
  if multipass info "$name" >/dev/null 2>&1; then
    log "Destroying VM ${name}"
    multipass delete --purge "$name" || true
  fi
  rm -rf "${VM_DIR:?}/${name}" 2>/dev/null || true
done

rm -f "${STATE_DIR}/node-token" "${STATE_DIR}/kubeconfig"
ok "Lab destroyed"
multipass list || true
