# AGENTS.md

## Repo Type
GitOps homelab IaC for a single Proxmox VE node. Three-layer pipeline:
`Packer` (VM templates) → `Terraform` (provision VMs/LXCs) → `Ansible` (configure services).
All documentation and code comments are in **Spanish**.

## Architecture

| Zone | Bridge | Subnet | Gateway |
|------|--------|--------|---------|
| Edge/ingress | `vmbr0` | `10.0.0.0/24` | `10.0.0.1` |
| Projects | `vmbr1` | `10.1.0.0/24` | `10.1.0.1` |
| Tools | `vmbr2` | `10.2.0.0/24` | `10.2.0.1` |

External access via Cloudflare Tunnel (no open ports). Admin via Tailscale VPN.

## Infrastructure Map

| ID | Name | Type | IP | Bridge |
|----|------|------|----|--------|
| 9000 | `ubuntu-2404-template` | Packer template | — | `vmbr0` |
| 100 | `traefik-edge` | VM | `10.0.0.10` | `vmbr0`+`vmbr1`+`vmbr2` |
| 101 | `adguard-dns` | LXC | `10.2.0.11` | `vmbr2` |
| 102 | `gitea-server` | LXC | `10.2.0.12` | `vmbr2` |
| 103 | `percona-db` | LXC | `10.2.0.13` | `vmbr2` |
| 104 | `cronmaster` | LXC | `10.2.0.14` | `vmbr2` |

## Common Commands

```bash
# Packer
cd packer/ubuntu-2404 && packer init . && packer build -var-file="secrets.pkrvars.hcl" ubuntu-2404.pkr.hcl

# Terraform (per workspace)
cd terraform/<workspace> && terraform init && terraform plan -var-file="terraform.tfvars" && terraform apply -var-file="terraform.tfvars"

# Ansible
cd ansible && ansible-galaxy collection install -r requirements.yml
ansible-playbook playbooks/<service>.yml --check --diff  # dry-run
```

## Critical Gotchas

- **Packer plugin**: Uses `hashicorp/proxmox` (proxmox-iso builder), NOT `bpg/proxmox`. The bpg/proxmox is for Terraform only.
- **LXC vs VM modules**: `terraform/modules/proxmox_vm/` is only for VMs. LXCs are defined inline under `apps_lxc/<service>/main.tf`.
- **Traefik htpasswd escaping**: In Docker Compose templates, `$` in bcrypt hashes must be written as `$$`. Example: `traefik_dashboard_auth: "admin:$$2y$$05$$..."`
- **Ansible SSH**: Uses `~/.ssh/tailscale` as `lpintos` with sudo. But LXC containers define `ansible_user: root` in inventory.
- **Module providers**: Modules do NOT have their own `providers.tf` — they inherit provider configuration from the workspace root.
- **Terraform workspaces**: Each subdirectory (edge_gateway, apps_lxc/*) is an independent workspace with its own state. No remote backend.
- **Secrets**: All secrets are git-ignored. Copy `.example` files and fill them in before running any tool.

## Secrets Files

| Tool | File | Template |
|------|------|----------|
| Packer | `packer/ubuntu-2404/secrets.pkrvars.hcl` | `secrets.pkrvars.hcl.example` |
| Terraform | `terraform/<workspace>/terraform.tfvars` | `terraform.tfvars.example` |
| Ansible | `ansible/inventory/group_vars/edge/secrets.yml` | `secrets.yml.example` |

## Adding a New Service

Typical workflow (example: Gitea):
1. `terraform/apps_lxc/gitea/main.tf` — define LXC inline (see existing `apps_lxc/gitea/`)
2. `terraform/apps_lxc/gitea/terraform.tfvars` — credentials
3. `ansible/inventory/hosts.yml` — add host to `apps` group
4. `ansible/roles/gitea_setup/` — create role with tasks, templates, handlers
5. `ansible/playbooks/gitea.yml` — playbook that calls the role
6. `ansible/roles/edge_proxy/templates/dynamic/<service>.yml.j2` — Traefik dynamic route
7. Run: `terraform init && terraform apply` then `ansible-playbook playbooks/gitea.yml`

## Inventory Groups

`edge` (VM, multi-NIC) · `apps` (LXCs, root SSH) · `databases` (LXCs, root SSH) · `tools` (LXCs, root SSH)

## References

- Full architecture docs: `README.md`
- Detailed runbooks: `CLAUDE.md`
- Ansible config: `ansible/ansible.cfg` (inventory, roles_path, SSH key, sudo)