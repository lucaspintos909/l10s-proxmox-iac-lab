
# ─── Contenedor LXC: Percona Server ──────────
resource "proxmox_virtual_environment_container" "percona" {
  description   = "Percona Database Server for Backend Apps (Red Interna vmbr2)"
  node_name     = var.proxmox_node
  vm_id         = 103
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
    dedicated = 2048
  }

  # ── Disco ──────────────────────────────────────────────────
  disk {
    datastore_id = "local-lvm"
    size         = 30
  }

  # ── Red ────────────────────────────────────────────────────
  network_interface {
    name   = "eth0"
    bridge = "vmbr2"
  }

  # ── Inicialización ─────────────────────────────────────────
  initialization {
    hostname = "percona-db"

    dns {
      servers = ["10.2.0.11", "1.1.1.1"] # Usando AdGuard como primario
    }

    ip_config {
      ipv4 {
        address = "10.2.0.13/24"
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
output "percona_lxc_id" {
  description = "ID del contenedor LXC de Percona"
  value       = proxmox_virtual_environment_container.percona.vm_id
}
