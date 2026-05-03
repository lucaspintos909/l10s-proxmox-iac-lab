# ─── Contenedor LXC: Hermes Agent (AI Agent Nous Research) ────────────
resource "proxmox_virtual_environment_container" "hermes" {
  description   = "Hermes Agent - AI Agent de Nous Research (Red vmbr2)"
  node_name     = var.proxmox_node
  vm_id         = 105
  started       = true
  start_on_boot = true

  unprivileged = true
  features {
    nesting = true
  }

  operating_system {
    template_file_id = "local:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
    type             = "ubuntu"
  }

  cpu {
    cores = 2
  }

  memory {
    dedicated = 2048
  }

  disk {
    datastore_id = "local-lvm"
    size         = 16
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr2"
  }

  initialization {
    hostname = "hermes-agent"

    dns {
      servers = ["1.1.1.1", "8.8.8.8"]
    }

    ip_config {
      ipv4 {
        address = "10.2.0.15/24"
        gateway = "10.2.0.1"
      }
    }

    user_account {
      keys     = [var.ssh_public_key]
      password = var.lxc_root_password
    }
  }
}

output "hermes_lxc_id" {
  description = "ID del contenedor LXC de Hermes"
  value       = proxmox_virtual_environment_container.hermes.vm_id
}
