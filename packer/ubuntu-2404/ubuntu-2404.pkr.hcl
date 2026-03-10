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
  type    = string
  default = ""
}

variable "proxmox_api_token_id" {
  type = string
}

variable "proxmox_api_token_secret" {
  type      = string
  sensitive = true
}

variable "ssh_public_key" {
  type        = string
  default     = ""
  description = "Mi clave pública SSH"
}

variable "proxmox_node" {
  type    = string
  default = "pve"
}

variable "vm_id" {
  type    = number
  default = 9000
}

variable "template_name" {
  type    = string
  default = "ubuntu-2404-template"
}

# ── Opción A: usar ISO ya cargada en Proxmox (activa) ──
variable "iso_file" {
  type        = string
  default     = "local:iso/ubuntu-24.04.2-live-server-amd64.iso"
  description = "Path to the ISO already uploaded in Proxmox (storage:iso/filename)"
}

# ── Opción B: descargar ISO y subirla a Proxmox (comentada) ──
# variable "iso_url" {
#   type    = string
#   default = "https://releases.ubuntu.com/noble/ubuntu-24.04.4-live-server-amd64.iso"
# }
#
# variable "iso_checksum" {
#   type    = string
#   default = "sha256:e907d92eeec9df64163a7e454cbc8d7755e8ddc7ed42f99dbc80c40f1a138433"
# }
#
# variable "iso_storage_pool" {
#   type    = string
#   default = "local"
# }

variable "ssh_username" {
  type    = string
  default = "lpintos"
}

variable "vm_ip" {
  type        = string
  default     = "10.0.0.100"
  description = "IP estática de la VM durante el build"
}

variable "vm_gateway" {
  type    = string
  default = "10.0.0.1"
}

variable "vm_dns" {
  type    = string
  default = "8.8.8.8,8.8.4.4"
}

variable "vm_cidr" {
  type        = number
  default     = 24
  description = "Netmask en notación CIDR (ej: 24 = 255.255.255.0)"
}

# ─── Source ──────────────────────────────────────────────

source "proxmox-iso" "ubuntu-2404" {
  proxmox_url              = var.proxmox_api_url
  username                 = var.proxmox_api_token_id
  token                    = var.proxmox_api_token_secret
  insecure_skip_tls_verify = true
  node                     = var.proxmox_node

  vm_id                = var.vm_id
  vm_name              = var.template_name
  template_description = "Ubuntu 24.04 LTS image — built with Packer"

  # ── Opción A: ISO local (activa) ──
  boot_iso {
    iso_file = var.iso_file
    unmount  = true
  }

  # ── Opción B: descargar ISO (comentada) ──
  # boot_iso {
  #   iso_url          = var.iso_url
  #   iso_checksum     = var.iso_checksum
  #   iso_storage_pool = var.iso_storage_pool
  #   unmount          = true
  # }

  os       = "l26"
  cores    = 2
  memory   = 4096
  cpu_type = "host"

  scsi_controller = "virtio-scsi-single"

  network_adapters {
    model  = "virtio"
    bridge = "vmbr0"
  }

  disks {
    disk_size    = "20G"
    storage_pool = "local-lvm"
    type         = "scsi"
  }

  cloud_init              = true
  cloud_init_storage_pool = "local-lvm"

  ssh_username = var.ssh_username
  ssh_timeout  = "20m"

  # Cloud-init config via CD-ROM (no requiere red entre laptop y VM)
  additional_iso_files {
    cd_label = "cidata"
    cd_content = {
      "user-data" = templatefile("${path.root}/http/user-data.pkrtpl.hcl", {
        ssh_public_key = var.ssh_public_key
        ssh_username   = var.ssh_username
        vm_ip          = var.vm_ip
        vm_gateway     = var.vm_gateway
        vm_dns         = var.vm_dns
        vm_cidr        = var.vm_cidr
      })
      "meta-data" = ""
    }
    iso_storage_pool = "local"
    unmount          = true
    type             = "sata"
    index            = "1"
  }

  boot_wait = "10s"
  boot_command = [
    "<esc><wait>",
    "e<wait>",
    "<down><down><down><end>",
    " autoinstall ds=nocloud",
    "<f10>"
  ]
}

# ─── Build ───────────────────────────────────────────────

build {
  name = "ubuntu-2404"

  sources = ["source.proxmox-iso.ubuntu-2404"]

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