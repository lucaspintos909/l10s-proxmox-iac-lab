# Diseño: Despliegue de CronMaster

**Fecha:** 2026-03-26

## Resumen

Despliegue de CronMaster como contenedor LXC en Proxmox, corriendo como servicio Node.js 22 vía systemd (sin Docker). Expuesto externamente via Traefik + Cloudflare Tunnel con autenticación por password.

## Arquitectura

Tres capas según el pipeline IaC del proyecto:

1. **Terraform** — provisiona el LXC en Proxmox
2. **Ansible** — instala y configura CronMaster como servicio systemd
3. **Traefik** — enruta el tráfico externo al LXC

## Terraform

Nuevo workspace: `terraform/apps_lxc/cronmaster/`

| Parámetro | Valor |
|---|---|
| `vm_id` | `104` |
| IP | `10.2.0.14/24` |
| Gateway | `10.2.0.1` |
| Bridge | `vmbr2` |
| DNS primario | `10.2.0.11` (AdGuard) |
| DNS secundario | `1.1.1.1` |
| CPU | 1 core |
| RAM | 512 MB |
| Disco | 8 GB (`local-lvm`) |
| `unprivileged` | `true` |
| `nesting` | no requerido |
| Hostname | `cronmaster` |
| OS template | `ubuntu-24.04-standard_24.04-2_amd64.tar.zst` |

Archivos: `main.tf`, `variables.tf`, `providers.tf`, `terraform.tfvars.example`

## Ansible

### Role: `cronmaster_setup`

Pasos del role (`roles/cronmaster_setup/tasks/main.yml`):

1. Instalar Node.js 22 via NodeSource apt repository
2. Descargar release `cronmaster_*_prebuild.tar.gz` desde `fccview/cronmaster` en GitHub a `/opt/cronmaster`
3. Crear `/opt/cronmaster/.env` (permisos 600) con:
   - `NODE_ENV=production`
   - `AUTH_PASSWORD` (desde secrets de Ansible)
   - `PORT=3000`
   - `HOSTNAME=0.0.0.0`
   - `NEXT_TELEMETRY_DISABLED=1`
4. Crear `/etc/systemd/system/cronmaster.service` (tipo simple, restart always, delay 10s, workdir `/opt/cronmaster`, comando `node server.js` como root)
5. `systemctl daemon-reload`, enable y start del servicio

### Secrets

`ansible/inventory/group_vars/apps/secrets.yml`:
- `cronmaster_auth_password` — password de acceso a la UI

Template de ejemplo: `secrets.yml.example`

### Playbook

`ansible/playbooks/cronmaster.yml` — aplica el role `cronmaster_setup` contra el host `cronmaster`.

### Inventario

Agregar `cronmaster` al grupo `apps` en `ansible/inventory/hosts.yml`:
```yaml
cronmaster:
  ansible_host: 10.2.0.14
  ansible_user: root
```

## Traefik

Nueva template: `ansible/roles/edge_proxy/templates/dynamic/cronmaster.yml.j2`

- Router rule: `Host('cronmaster.{{ domain }}')`
- EntryPoint: `websecure`
- TLS: `certResolver: cloudflare`
- Backend: `http://10.2.0.14:3000`

El playbook `edge.yml` existente desplegará la template al re-ejecutarse.

## Flujo de despliegue

```
terraform apply   →  LXC provisionado en 10.2.0.14
ansible-playbook playbooks/cronmaster.yml  →  Node.js + servicio systemd
ansible-playbook playbooks/edge.yml        →  Traefik route cronmaster.domain
```
