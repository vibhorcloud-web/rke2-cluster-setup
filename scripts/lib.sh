#!/usr/bin/env bash
# Shared helpers. Source me, don't run me.
# shellcheck disable=SC2034,SC1091

set -euo pipefail

RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[1;33m'
BLUE=$'\033[0;34m'; CYAN=$'\033[0;36m'; NC=$'\033[0m'

log()  { printf '%s[slinky]%s %s\n' "$BLUE"   "$NC" "$*" >&2; }
ok()   { printf '%s[slinky]%s %s\n' "$GREEN"  "$NC" "$*" >&2; }
warn() { printf '%s[slinky]%s %s\n' "$YELLOW" "$NC" "$*" >&2; }
err()  { printf '%s[slinky]%s %s\n' "$RED"    "$NC" "$*" >&2; }
die()  { err "$*"; exit 1; }

# Locate repo root and load config
__LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_ROOT_DETECTED="$(cd "${__LIB_DIR}/.." && pwd)"
source "${LAB_ROOT_DETECTED}/config.env"

ssh_opts=(
  -i "${SSH_KEY}"
  -o StrictHostKeyChecking=no
  -o UserKnownHostsFile=/dev/null
  -o BatchMode=yes
  -o ConnectTimeout=5
  -o LogLevel=ERROR
)

ssh_run() {
  local host=$1; shift
  ssh -T "${ssh_opts[@]}" "${SSH_USER}@${host}" "$@"
}

scp_to() {
  local src=$1 host=$2 dst=$3
  scp "${ssh_opts[@]}" "$src" "${SSH_USER}@${host}:${dst}"
}

scp_from() {
  local host=$1 src=$2 dst=$3
  scp "${ssh_opts[@]}" "${SSH_USER}@${host}:${src}" "$dst"
}

wait_for_ssh() {
  local host=$1
  local timeout=${2:-300}
  local start=$SECONDS
  while ! ssh_run "$host" true 2>/dev/null; do
    (( SECONDS - start > timeout )) && die "Timeout waiting for SSH on ${host}"
    sleep 3
  done
}

# Multipass helpers
multipass_ip() {
  local name=$1
  local ip
  ip=$(multipass info "$name" --format json 2>/dev/null | jq -r ".info[\"$name\"].ipv4[0] // empty")
  echo "$ip"
}

control_plane_ip() {
  local name cpus mem disk role
  for entry in "${VM_LIST[@]}"; do
    read -r name cpus mem disk role <<<"$entry"
    if [[ "$role" == "server" ]]; then
      multipass_ip "$name"
      return 0
    fi
  done
  return 1
}

control_plane_name() {
  local name cpus mem disk role
  for entry in "${VM_LIST[@]}"; do
    read -r name cpus mem disk role <<<"$entry"
    if [[ "$role" == "server" ]]; then
      echo "$name"
      return 0
    fi
  done
  return 1
}

host_lan_ip() {
  # macOS native way to get primary LAN IP
  ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || true
}
