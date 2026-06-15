#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

[[ -f "${SSH_KEY}.pub" ]] || die "SSH key missing — run 00-host-prep.sh"

PUBKEY="$(cat "${SSH_KEY}.pub")"

create_vm() {
  local name=$1 cpus=$2 mem=$3 disk=$4
  local vm_dir="${VM_DIR}/${name}"
  local user_data="${vm_dir}/user-data.yaml"

  if multipass info "${name}" >/dev/null 2>&1; then
    warn "VM ${name} already defined — skipping (use 99-destroy.sh to reset)"
    return 0
  fi

  log "Creating ${name}: ${cpus} vCPU / ${mem} / ${disk}"
  mkdir -p "${vm_dir}"

  cat > "${user_data}" <<EOF
#cloud-config
hostname: ${name}
manage_etc_hosts: true
ssh_pwauth: false
users:
  - name: ${SSH_USER}
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    lock_passwd: true
    ssh_authorized_keys:
      - ${PUBKEY}
package_update: true
packages:
  - curl
  - jq
  - iproute2
  - apparmor-utils
write_files:
  - path: /etc/modules-load.d/k8s.conf
    content: |
      br_netfilter
      overlay
  - path: /etc/sysctl.d/99-k8s.conf
    content: |
      net.bridge.bridge-nf-call-iptables = 1
      net.bridge.bridge-nf-call-ip6tables = 1
      net.ipv4.ip_forward = 1
runcmd:
  - swapoff -a
  - sed -i.bak '/\sswap\s/ s/^/#/' /etc/fstab
  - modprobe br_netfilter
  - modprobe overlay
  - sysctl --system
EOF

  multipass launch "${UBUNTU_RELEASE}" \
    --name "${name}" \
    --cpus "${cpus}" \
    --memory "${mem}" \
    --disk "${disk}" \
    --cloud-init "${user_data}" \
    --timeout 600
}

for entry in "${VM_LIST[@]}"; do
  read -r name cpus mem disk role <<<"$entry"
  create_vm "$name" "$cpus" "$mem" "$disk"
done

log "Waiting for SSH on each VM (cloud-init can take a minute or two)…"
for entry in "${VM_LIST[@]}"; do
  read -r name cpus mem disk role <<<"$entry"
  
  # Multipass might take a moment to assign an IP
  for _ in {1..30}; do
    ip="$(multipass_ip "$name")"
    [[ -n "$ip" ]] && break
    sleep 2
  done
  
  [[ -z "$ip" ]] && die "Could not find IP for ${name}"
  log "  ${name} — ${ip}"
  wait_for_ssh "$ip" 600
  ok "  ${name} reachable"
done

ok "All VMs running"
multipass list
