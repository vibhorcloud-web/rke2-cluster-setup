#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

log "Host pre-flight"

if [[ "$(uname -s)" != "Darwin" ]]; then
  die "This lab is optimized for macOS. Please run on a Mac."
fi

log "Installing prerequisites via Homebrew (multipass, kubectl, jq, gettext)"
brew install multipass kubectl jq gettext || true

# Make sure envsubst is available (brew installs gettext keg-only sometimes)
if ! command -v envsubst >/dev/null 2>&1; then
  export PATH="$(brew --prefix gettext)/bin:$PATH"
fi

mkdir -p "${VM_DIR}" "${STATE_DIR}"
chmod 755 "${VM_DIR}"

# SSH key for the lab
if [[ ! -f "${SSH_KEY}" ]]; then
  log "Generating SSH keypair at ${SSH_KEY}"
  ssh-keygen -t ed25519 -N '' -f "${SSH_KEY}" -C "slurm-lab" >/dev/null
fi
chmod 600 "${SSH_KEY}"

ok "Host prep complete"
