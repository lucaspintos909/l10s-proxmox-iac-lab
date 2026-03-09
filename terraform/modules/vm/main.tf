# ─── Reusable Proxmox VM Module ──────────────────────────
# Clones from a Cloud-Init-enabled template and configures
# networking, resources, and SSH access.

resource "proxmox_virtual_environment_vm" "vm" {
  name      = var.vm_name
  node_name = var.target_node
  vm_id     = var.vm_id
  tags      = var.tags

  clone {
    vm_id = var.template_id
    full  = true
  }

  cpu {
    cores = var.cores
    type  = "host"
  }

  memory {
    dedicated = var.memory
  }

  disk {
    datastore_id = var.storage_pool
    size         = var.disk
    interface    = "scsi0"
  }

  network_device {
    bridge = var.bridge
    model  = "virtio"
  }

  # Cloud-Init configuration
  initialization {
    user_account {
      username = var.ci_user
      keys     = [var.ssh_public_key]
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

  agent {
    enabled = true
  }

  lifecycle {
    ignore_changes = [
      disk[0].size,
    ]
  }
}
