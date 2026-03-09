packer {
  required_plugins {
    proxmox = {
      version = ">= 1.2.2"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

# ─── Variables ───────────────────────────────────────────

variable "proxmox_api_url" {
  type        = string
  description = "Proxmox API URL (e.g. https://10.0.0.1:8006/api2/json)"
}

variable "proxmox_api_token_id" {
  type        = string
  description = "API token ID (e.g. terraform@pve!packer)"
}

variable "proxmox_api_token_secret" {
  type        = string
  sensitive   = true
  description = "API token secret"
}

variable "proxmox_node" {
  type    = string
  default = "pve"
}

variable "template_id" {
  type    = number
  default = 9000
}

variable "template_name" {
  type    = string
  default = "ubuntu-2404-template"
}

variable "iso_url" {
  type    = string
  default = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
}

variable "iso_checksum" {
  type    = string
  default = "file:https://cloud-images.ubuntu.com/noble/current/SHA256SUMS"
}

variable "ssh_username" {
  type    = string
  default = "ubuntu"
}

# ─── Source ──────────────────────────────────────────────

source "proxmox-clone" "ubuntu-2404" {
  proxmox_url              = var.proxmox_api_url
  username                 = var.proxmox_api_token_id
  token                    = var.proxmox_api_token_secret
  insecure_skip_tls_verify = true
  node                     = var.proxmox_node

  clone_vm_id = var.template_id

  vm_name              = var.template_name
  template_description = "Ubuntu 24.04 LTS golden image — built by Packer"

  cores  = 2
  memory = 2048

  scsi_controller = "virtio-scsi-single"

  disks {
    disk_size    = "10G"
    storage_pool = "local-lvm"
    type         = "scsi"
  }

  network_adapters {
    model  = "virtio"
    bridge = "vmbr0"
  }

  cloud_init              = true
  cloud_init_storage_pool = "local-lvm"

  ssh_username = var.ssh_username
  ssh_timeout  = "20m"
}

# ─── Build ───────────────────────────────────────────────

build {
  name = "ubuntu-2404"

  sources = ["source.proxmox-clone.ubuntu-2404"]

  # Install essential packages
  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y qemu-guest-agent cloud-init python3 python3-pip",
      "sudo systemctl enable qemu-guest-agent",
    ]
  }

  # Clean up for template conversion
  provisioner "shell" {
    inline = [
      "sudo cloud-init clean",
      "sudo apt-get autoremove -y",
      "sudo apt-get clean",
      "sudo rm -rf /tmp/* /var/tmp/*",
      "sudo truncate -s 0 /etc/machine-id",
      "sudo sync",
    ]
  }
}
