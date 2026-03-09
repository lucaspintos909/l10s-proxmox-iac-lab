#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PACKER_DIR="$REPO_ROOT/packer/ubuntu-2404"
TERRAFORM_DIR="$REPO_ROOT/terraform"
ANSIBLE_DIR="$REPO_ROOT/ansible"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log()  { echo -e "${GREEN}[deploy]${NC} $1"; }
warn() { echo -e "${YELLOW}[deploy]${NC} $1"; }
err()  { echo -e "${RED}[deploy]${NC} $1" >&2; exit 1; }

# ─── Phase 1: Packer (Golden Image) ─────────────────────
log "Phase 1: Building golden image..."
if command -v packer &> /dev/null; then
  cd "$PACKER_DIR"
  packer init .
  packer build .
  log "Golden image built successfully."
else
  warn "Packer not found — skipping golden image build."
  warn "Make sure the VM template (ID 9000) already exists in Proxmox."
fi

# ─── Phase 2: Terraform / OpenTofu ──────────────────────
log "Phase 2: Provisioning infrastructure with OpenTofu..."
cd "$TERRAFORM_DIR"
tofu init -input=false
tofu apply -auto-approve
log "Infrastructure provisioned successfully."

# ─── Wait for VMs to boot ───────────────────────────────
log "Waiting 30s for VMs/LXC to boot and initialize Cloud-Init..."
sleep 30

# ─── Phase 3: Ansible ───────────────────────────────────
log "Phase 3: Configuring hosts with Ansible..."
cd "$ANSIBLE_DIR"
ansible-playbook playbooks/site.yml
log "Configuration complete."

# ─── Done ────────────────────────────────────────────────
echo ""
log "═══════════════════════════════════════════════"
log "  Deployment complete! 🚀"
log "  ─────────────────────────────────────────────"
log "  Traefik:     http://10.0.0.10:8080"
log "  Gitea:       http://10.0.0.10:3000"
log "  Vaultwarden: http://10.0.0.10:8843"
log "  Portainer:   http://10.0.0.10:9443"
log "  Uptime Kuma: http://10.0.0.20:3001"
log "═══════════════════════════════════════════════"
