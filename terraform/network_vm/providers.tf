terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmoxve"
      version = "~> 0.66.0"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_api_url
  api_token = "${var.proxmox_api_token_id}=${var.proxmox_api_token_secret}"
  insecure  = true
}
