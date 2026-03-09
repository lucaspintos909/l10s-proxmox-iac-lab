# ─── Reusable Proxmox LXC Module ─────────────────────────
# Creates a Linux Container with static IP and SSH access.

resource "proxmox_virtual_environment_container" "lxc" {
  description   = "Managed by OpenTofu"
  node_name     = var.target_node
  vm_id         = var.vm_id
  tags          = var.tags
  unprivileged  = true
  start_on_boot = true

  operating_system {
    template_file_id = var.os_template
    type             = "ubuntu"
  }

  cpu {
    cores = var.cores
  }

  memory {
    dedicated = var.memory
  }

  disk {
    datastore_id = var.storage_pool
    size         = var.disk
  }

  network_interface {
    name   = "eth0"
    bridge = var.bridge
  }

  initialization {
    hostname = var.container_name

    user_account {
      keys = [var.ssh_public_key]
    }

    ip_config {
      ipv4 {
        address = var.ip_address
        gateway = var.gateway
      }
    }

    dns {
      servers = var.dns_servers
    }
  }

  features {
    nesting = true
  }
}
