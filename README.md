# 🏠 proxmox-l10s — Home Lab Infrastructure as Code

Fully automated Proxmox VE home lab managed with **OpenTofu** (provisioning) and **Ansible** (configuration).

## Architecture

```
Workstation ──► Proxmox API (10.0.0.1:8006)
                 ├─ VM: docker-host  (10.0.0.10) — Traefik, Gitea, Vaultwarden, Portainer
                 └─ LXC: monitoring  (10.0.0.20) — Uptime Kuma
```

## Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| OpenTofu | ≥ 1.8 | [opentofu.org](https://opentofu.org/docs/intro/install/) |
| Packer | ≥ 1.11 | [packer.io](https://developer.hashicorp.com/packer/install) |
| Ansible | ≥ 2.16 | `pip install ansible ansible-lint` |
| Make | any | Pre-installed on most Linux distros |

## Quick Start

```bash
# 1. Clone the repo
git clone https://github.com/<your-user>/proxmox-l10s.git
cd proxmox-l10s

# 2. Copy and edit variable files
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
cp packer/ubuntu-2404/variables.pkrvars.hcl.example packer/ubuntu-2404/variables.pkrvars.hcl
# Edit both files with your Proxmox credentials

# 3. Create Ansible vault (secrets)
cd ansible && ansible-vault create group_vars/vault.yml

# 4. Full deployment
make deploy
```

## Make Targets

```bash
make help              # Show all available targets
make packer-build      # Build the Ubuntu 24.04 VM template
make init              # Initialize OpenTofu
make plan              # Preview infrastructure changes
make apply             # Provision VMs and LXC containers
make ansible-run       # Configure all hosts with Ansible
make deploy            # Full pipeline: Packer → Tofu → Ansible
make destroy           # Tear down all infrastructure
```

## Directory Structure

```
├── packer/            # Golden image (Ubuntu 24.04 VM template)
├── terraform/         # Infrastructure provisioning (VMs, LXC)
│   └── modules/       # Reusable VM and LXC modules
├── ansible/           # Configuration management
│   ├── playbooks/     # Orchestration playbooks
│   └── roles/         # Per-service roles
├── scripts/           # Deployment helpers
└── Makefile           # Convenience targets
```

## Secrets Management

- **Ansible Vault** encrypts sensitive variables in `ansible/group_vars/vault.yml`
- **Vaultwarden** (self-hosted) manages browser/app passwords
- `terraform.tfvars` and `*.pkrvars.hcl` are gitignored — never commit credentials

## License

Private — personal home lab infrastructure.
