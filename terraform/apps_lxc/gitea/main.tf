

# ─── Contenedor LXC: Gitea Server ──────────
resource "proxmox_virtual_environment_container" "gitea" {
  description   = "Gitea Server - Private Git (Red Interna vmbr2)"
  node_name     = var.proxmox_node
  vm_id         = 102
  started       = true
  start_on_boot = true

  # Contenedor sin privilegios + nesting para compatibilidad
  unprivileged = true
  features {
    nesting = true
  }

  # ── Sistema Operativo ──────────────────────────────────────
  operating_system {
    template_file_id = "local:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
    type             = "ubuntu"
  }

  # ── CPU y Memoria ──────────────────────────────────────────
  cpu {
    cores = 2
  }

  memory {
    dedicated = 1024
  }

  # ── Disco ──────────────────────────────────────────────────
  disk {
    datastore_id = "local-lvm"
    size         = 15
  }

  # ── Red ────────────────────────────────────────────────────
  network_interface {
    name   = "eth0"
    bridge = "vmbr2"
  }

  # ── Inicialización ─────────────────────────────────────────
  initialization {
    hostname = "gitea-server"

    dns {
      servers = ["10.2.0.11", "1.1.1.1"] # Usando AdGuard como primario si es posible
    }

    ip_config {
      ipv4 {
        address = "10.2.0.12/24"
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
output "gitea_lxc_id" {
  description = "ID del contenedor LXC de Gitea"
  value       = proxmox_virtual_environment_container.gitea.vm_id
}
