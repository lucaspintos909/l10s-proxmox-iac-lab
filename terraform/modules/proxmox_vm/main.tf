resource "proxmox_virtual_environment_vm" "this" {
  name        = var.name
  node_name   = var.node_name
  vm_id       = var.vm_id
  description = var.description
  tags        = var.tags
  on_boot     = true

  agent {
    enabled = true
  }

  clone {
    vm_id = var.template_vmid
    full  = true
  }

  cpu {
    cores = var.cpu_cores
    type  = "host"
  }

  memory {
    dedicated = var.memory
  }

  disk {
    datastore_id = var.datastore_id
    interface    = "scsi0"
    size         = var.disk_size
    file_format  = "raw"
  }

  dynamic "network_device" {
    for_each = var.network_interfaces
    content {
      bridge = network_device.value.bridge
    }
  }

  initialization {
    datastore_id = var.datastore_id

    dns {
      servers = ["1.1.1.1", "8.8.8.8"]
    }

    dynamic "ip_config" {
      for_each = var.network_interfaces
      content {
        ipv4 {
          address = ip_config.value.address
          gateway = ip_config.value.gateway
        }
      }
    }
    
    user_account {
      username = var.ssh_username
      keys     = [var.ssh_public_key]
    }
  }
}
