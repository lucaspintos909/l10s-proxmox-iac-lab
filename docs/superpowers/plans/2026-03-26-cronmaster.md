# CronMaster Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Desplegar CronMaster como contenedor LXC en Proxmox (vm_id 104, 10.2.0.14), corriendo Node.js 22 vía systemd, expuesto via Traefik + Cloudflare con autenticación por password.

**Architecture:** Terraform provisiona el LXC en `vmbr2`; Ansible instala Node.js 22, descarga el prebuild de GitHub y configura un servicio systemd; el playbook `edge.yml` existente despliega la ruta de Traefik al re-ejecutarse.

**Tech Stack:** Terraform (bpg/proxmox), Ansible, Node.js 22, systemd, Traefik

---

## Mapa de archivos

| Acción   | Archivo |
|----------|---------|
| Crear    | `terraform/apps_lxc/cronmaster/providers.tf` |
| Crear    | `terraform/apps_lxc/cronmaster/variables.tf` |
| Crear    | `terraform/apps_lxc/cronmaster/main.tf` |
| Crear    | `terraform/apps_lxc/cronmaster/terraform.tfvars.example` |
| Crear    | `ansible/roles/cronmaster_setup/defaults/main.yml` |
| Crear    | `ansible/roles/cronmaster_setup/tasks/main.yml` |
| Crear    | `ansible/roles/cronmaster_setup/handlers/main.yml` |
| Crear    | `ansible/roles/cronmaster_setup/templates/cronmaster.env.j2` |
| Crear    | `ansible/roles/cronmaster_setup/templates/cronmaster.service.j2` |
| Crear    | `ansible/playbooks/cronmaster.yml` |
| Crear    | `ansible/roles/edge_proxy/templates/dynamic/cronmaster.yml.j2` |
| Modificar | `ansible/inventory/hosts.yml` |
| Modificar | `ansible/inventory/group_vars/all/secrets.yml` |

---

## Task 1: Terraform — workspace cronmaster

**Files:**
- Crear: `terraform/apps_lxc/cronmaster/providers.tf`
- Crear: `terraform/apps_lxc/cronmaster/variables.tf`
- Crear: `terraform/apps_lxc/cronmaster/main.tf`
- Crear: `terraform/apps_lxc/cronmaster/terraform.tfvars.example`

- [ ] **Step 1: Crear providers.tf** (idéntico al de gitea)

```hcl
terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.66.0"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_api_url
  api_token = "${var.proxmox_api_token_id}=${var.proxmox_api_token_secret}"
  insecure  = true
}
```

- [ ] **Step 2: Crear variables.tf** (idéntico al de gitea)

```hcl
variable "proxmox_api_url" {
  description = "URL de la API de Proxmox"
  type        = string
}

variable "proxmox_api_token_id" {
  description = "ID del token API (ej: root@pam!terraform)"
  type        = string
}

variable "proxmox_api_token_secret" {
  description = "Secret del token API"
  type        = string
  sensitive   = true
}

variable "proxmox_node" {
  description = "Nodo de Proxmox donde desplegar el LXC"
  type        = string
  default     = "pve"
}

variable "ssh_public_key" {
  description = "Clave pública SSH para acceso root al LXC"
  type        = string
}

variable "lxc_root_password" {
  description = "Contraseña del usuario root del LXC"
  type        = string
  sensitive   = true
}
```

- [ ] **Step 3: Crear main.tf**

```hcl
# ─── Contenedor LXC: CronMaster ──────────
resource "proxmox_virtual_environment_container" "cronmaster" {
  description   = "CronMaster - Gestión de Cron Jobs vía Web UI (Red Interna vmbr2)"
  node_name     = var.proxmox_node
  vm_id         = 104
  started       = true
  start_on_boot = true

  unprivileged = true

  # ── Sistema Operativo ──────────────────────────────────────
  operating_system {
    template_file_id = "local:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
    type             = "ubuntu"
  }

  # ── CPU y Memoria ──────────────────────────────────────────
  cpu {
    cores = 1
  }

  memory {
    dedicated = 512
  }

  # ── Disco ──────────────────────────────────────────────────
  disk {
    datastore_id = "local-lvm"
    size         = 8
  }

  # ── Red ────────────────────────────────────────────────────
  network_interface {
    name   = "eth0"
    bridge = "vmbr2"
  }

  # ── Inicialización ─────────────────────────────────────────
  initialization {
    hostname = "cronmaster"

    dns {
      servers = ["10.2.0.11", "1.1.1.1"]
    }

    ip_config {
      ipv4 {
        address = "10.2.0.14/24"
        gateway = "10.2.0.1"
      }
    }

    user_account {
      keys     = [var.ssh_public_key]
      password = var.lxc_root_password
    }
  }
}

# ─── Outputs ─────────────────────────────────────────────────
output "cronmaster_lxc_id" {
  description = "ID del contenedor LXC de CronMaster"
  value       = proxmox_virtual_environment_container.cronmaster.vm_id
}
```

- [ ] **Step 4: Crear terraform.tfvars.example**

```hcl
proxmox_api_url         = "https://10.X.X.X:8006/"
proxmox_api_token_id     = "root@pam!terraform"
proxmox_api_token_secret = "tu-secret-uuid"
proxmox_node             = "pve"
ssh_public_key           = "ssh-ed25519 AAAAC3... tu_usuario@host"
lxc_root_password        = "P0t4t0..."
```

- [ ] **Step 5: Crear terraform.tfvars** (copiando del .example y completando con valores reales — NO commitear)

```bash
cp terraform/apps_lxc/cronmaster/terraform.tfvars.example \
   terraform/apps_lxc/cronmaster/terraform.tfvars
# Editar con los valores reales (mismos que gitea/terraform.tfvars)
```

- [ ] **Step 6: Inicializar y verificar el plan**

```bash
cd terraform/apps_lxc/cronmaster
terraform init
terraform plan -var-file="terraform.tfvars"
```

Salida esperada: `Plan: 1 to add, 0 to change, 0 to destroy.` con el LXC `cronmaster` vm_id=104 en 10.2.0.14.

- [ ] **Step 7: Commit**

```bash
git add terraform/apps_lxc/cronmaster/providers.tf \
        terraform/apps_lxc/cronmaster/variables.tf \
        terraform/apps_lxc/cronmaster/main.tf \
        terraform/apps_lxc/cronmaster/terraform.tfvars.example
git commit -m "feat: agrega workspace Terraform para LXC cronmaster (vm_id 104)"
```

---

## Task 2: Inventario y secrets

**Files:**
- Modificar: `ansible/inventory/hosts.yml`
- Modificar: `ansible/inventory/group_vars/all/secrets.yml`

- [ ] **Step 1: Agregar cronmaster al inventario**

En `ansible/inventory/hosts.yml`, agregar dentro del bloque `apps:` → `hosts:`:

```yaml
        cronmaster:
          ansible_host: 10.2.0.14
          ansible_user: root
```

El archivo completo queda:

```yaml
---
all:
  children:
    edge:
      hosts:
        traefik-edge:
          ansible_host: 10.0.0.10
    apps:
      hosts:
        gitea-server:
          ansible_host: 10.2.0.12
          ansible_user: root
        cronmaster:
          ansible_host: 10.2.0.14
          ansible_user: root
    databases:
      hosts:
        percona-db:
          ansible_host: 10.2.0.13
          ansible_user: root
    tools:
      hosts:
        adguard-dns:
          ansible_host: 10.2.0.11
          ansible_user: root
```

- [ ] **Step 2: Agregar secret cronmaster_auth_password**

En `ansible/inventory/group_vars/all/secrets.yml`, agregar al final:

```yaml
cronmaster_auth_password: "tu_password_seguro"
```

- [ ] **Step 3: Commit**

```bash
git add ansible/inventory/hosts.yml
git commit -m "feat: agrega cronmaster al inventario de Ansible"
# NO commitear secrets.yml (ya está en .gitignore por el patrón existente)
```

---

## Task 3: Ansible role cronmaster_setup

**Files:**
- Crear: `ansible/roles/cronmaster_setup/defaults/main.yml`
- Crear: `ansible/roles/cronmaster_setup/tasks/main.yml`
- Crear: `ansible/roles/cronmaster_setup/handlers/main.yml`
- Crear: `ansible/roles/cronmaster_setup/templates/cronmaster.env.j2`
- Crear: `ansible/roles/cronmaster_setup/templates/cronmaster.service.j2`

- [ ] **Step 1: Crear defaults/main.yml**

```yaml
---
cronmaster_install_dir: /opt/cronmaster
cronmaster_port: 3000
```

- [ ] **Step 2: Crear handlers/main.yml**

```yaml
---
- name: Restart CronMaster
  ansible.builtin.systemd:
    name: cronmaster
    state: restarted
    daemon_reload: true
```

- [ ] **Step 3: Crear template cronmaster.env.j2**

```
NODE_ENV=production
AUTH_PASSWORD={{ cronmaster_auth_password }}
PORT={{ cronmaster_port }}
HOSTNAME=0.0.0.0
NEXT_TELEMETRY_DISABLED=1
```

- [ ] **Step 4: Crear template cronmaster.service.j2**

```ini
[Unit]
Description=CronMaster - Gestión de Cron Jobs vía Web UI
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory={{ cronmaster_install_dir }}
ExecStart=/usr/bin/node {{ cronmaster_install_dir }}/server.js
EnvironmentFile={{ cronmaster_install_dir }}/.env
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

- [ ] **Step 5: Crear tasks/main.yml**

```yaml
---
# 0. Instalar dependencias
- name: Instalar curl
  ansible.builtin.apt:
    name: curl
    state: present

# 1. Instalar Node.js 22 via NodeSource
- name: Agregar repositorio NodeSource Node.js 22
  ansible.builtin.shell:
    cmd: curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
    creates: /etc/apt/sources.list.d/nodesource.list

- name: Instalar Node.js 22
  ansible.builtin.apt:
    name: nodejs
    state: present
    update_cache: true

# 2. Determinar si se necesita instalar o actualizar
- name: Verificar si existe archivo de versión instalada
  ansible.builtin.stat:
    path: "{{ cronmaster_install_dir }}/.version"
  register: cronmaster_version_file

- name: Leer versión instalada
  ansible.builtin.slurp:
    src: "{{ cronmaster_install_dir }}/.version"
  register: cronmaster_installed_version_raw
  when: cronmaster_version_file.stat.exists

- name: Obtener última versión de CronMaster desde GitHub
  ansible.builtin.uri:
    url: "https://api.github.com/repos/fccview/cronmaster/releases/latest"
    return_content: true
  register: cronmaster_gh_release

- name: Establecer variables de versión
  ansible.builtin.set_fact:
    cronmaster_remote_version: "{{ cronmaster_gh_release.json.tag_name }}"
    cronmaster_installed_version: >-
      {{ (cronmaster_installed_version_raw.content | b64decode | trim)
         if cronmaster_version_file.stat.exists else '' }}

- name: Establecer si requiere instalación o actualización
  ansible.builtin.set_fact:
    cronmaster_needs_install: "{{ cronmaster_installed_version != cronmaster_gh_release.json.tag_name }}"

# 3. Descargar y desplegar
- name: Crear directorio de instalación {{ cronmaster_install_dir }}
  ansible.builtin.file:
    path: "{{ cronmaster_install_dir }}"
    state: directory
    mode: '0755'
  when: cronmaster_needs_install

- name: Descargar tarball prebuild de CronMaster {{ cronmaster_gh_release.json.tag_name }}
  ansible.builtin.get_url:
    url: >-
      {{ cronmaster_gh_release.json.assets
         | selectattr('name', 'match', 'cronmaster_.*_prebuild\\.tar\\.gz')
         | map(attribute='browser_download_url')
         | first }}
    dest: /tmp/cronmaster_prebuild.tar.gz
    mode: '0644'
  when: cronmaster_needs_install

- name: Extraer CronMaster a {{ cronmaster_install_dir }}
  ansible.builtin.unarchive:
    src: /tmp/cronmaster_prebuild.tar.gz
    dest: "{{ cronmaster_install_dir }}"
    remote_src: true
  when: cronmaster_needs_install
  notify: Restart CronMaster

- name: Guardar versión instalada
  ansible.builtin.copy:
    content: "{{ cronmaster_gh_release.json.tag_name }}"
    dest: "{{ cronmaster_install_dir }}/.version"
    mode: '0644'
  when: cronmaster_needs_install

# 4. Configurar .env
- name: Desplegar archivo .env
  ansible.builtin.template:
    src: cronmaster.env.j2
    dest: "{{ cronmaster_install_dir }}/.env"
    owner: root
    group: root
    mode: '0600'
  notify: Restart CronMaster

# 5. Configurar servicio systemd
- name: Desplegar cronmaster.service
  ansible.builtin.template:
    src: cronmaster.service.j2
    dest: /etc/systemd/system/cronmaster.service
    owner: root
    group: root
    mode: '0644'
  notify: Restart CronMaster

# 6. Habilitar e iniciar servicio
- name: Habilitar e iniciar el servicio cronmaster
  ansible.builtin.systemd:
    name: cronmaster
    enabled: true
    state: started
    daemon_reload: true
```

- [ ] **Step 6: Commit**

```bash
git add ansible/roles/cronmaster_setup/
git commit -m "feat: agrega role Ansible cronmaster_setup"
```

---

## Task 4: Playbook y ruta Traefik

**Files:**
- Crear: `ansible/playbooks/cronmaster.yml`
- Crear: `ansible/roles/edge_proxy/templates/dynamic/cronmaster.yml.j2`

- [ ] **Step 1: Crear playbook cronmaster.yml**

```yaml
---
- name: Setup CronMaster
  hosts: cronmaster
  become: true

  pre_tasks:
    - name: Actualizar cache de APT
      ansible.builtin.apt:
        update_cache: true
        cache_valid_time: 3600

  roles:
    - role: cronmaster_setup
```

- [ ] **Step 2: Crear template Traefik cronmaster.yml.j2**

```yaml
http:
  routers:
    cronmaster:
      rule: "Host(`cronmaster.{{ domain }}`)"
      entryPoints:
        - "websecure"
      service: "cronmaster-service"
      tls:
        certResolver: "cloudflare"

  services:
    cronmaster-service:
      loadBalancer:
        servers:
          - url: "http://10.2.0.14:3000"
```

- [ ] **Step 3: Commit**

```bash
git add ansible/playbooks/cronmaster.yml \
        ansible/roles/edge_proxy/templates/dynamic/cronmaster.yml.j2
git commit -m "feat: agrega playbook cronmaster y ruta Traefik"
```

---

## Task 5: Deploy completo

- [ ] **Step 1: Aplicar Terraform**

```bash
cd terraform/apps_lxc/cronmaster
terraform apply -var-file="terraform.tfvars"
```

Salida esperada: `Apply complete! Resources: 1 added, 0 changed, 0 destroyed.`
El LXC debe aparecer en Proxmox con IP 10.2.0.14 y estado `running`.

- [ ] **Step 2: Esperar SSH y verificar conectividad**

```bash
# Esperar ~30s a que el LXC arranque, luego:
ssh -i ~/.ssh/tailscale root@10.2.0.14 "echo OK"
```

Salida esperada: `OK`

- [ ] **Step 3: Dry-run Ansible cronmaster**

```bash
cd ansible
ansible-playbook playbooks/cronmaster.yml --check --diff
```

Salida esperada: tareas en verde/amarillo, sin errores rojos. Si alguna tarea falla en `--check` por ser el primer despliegue (ej. unarchive sobre directorio inexistente), es esperado — continuar con apply.

- [ ] **Step 4: Aplicar Ansible cronmaster**

```bash
ansible-playbook playbooks/cronmaster.yml
```

Salida esperada: play recap sin `failed`. Verificar que el servicio está activo:

```bash
ssh -i ~/.ssh/tailscale root@10.2.0.14 "systemctl status cronmaster"
```

Debe mostrar `active (running)`.

- [ ] **Step 5: Verificar que server.js existe en el directorio correcto**

```bash
ssh -i ~/.ssh/tailscale root@10.2.0.14 "ls /opt/cronmaster/server.js"
```

Si el tarball extrae con un subdirectorio en vez de directamente en `/opt/cronmaster`, los archivos estarán en `/opt/cronmaster/<subdir>/server.js`. En ese caso, actualizar el task de `unarchive` en `tasks/main.yml` para agregar `extra_opts: ["--strip-components=1"]` y re-ejecutar.

- [ ] **Step 6: Aplicar Ansible edge (desplegar ruta Traefik)**

```bash
ansible-playbook playbooks/edge.yml
```

Salida esperada: play recap sin `failed`. La template `cronmaster.yml` debe aparecer en el directorio dinámico de Traefik.

- [ ] **Step 7: Verificar acceso web**

Abrir `https://cronmaster.<tu-dominio>` en el navegador.
Debe cargar la pantalla de login de CronMaster pidiendo password.

- [ ] **Step 8: Commit final de estado**

```bash
git add ansible/inventory/group_vars/all/secrets.yml  # solo si hay cambios en el .example
# Nota: secrets.yml real NO se commitea
git status  # verificar que no queden archivos sin commitear
```
