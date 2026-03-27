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
