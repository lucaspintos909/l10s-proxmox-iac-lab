# ─── Proxmox Connection ──────────────────────────────────

variable "proxmox_api_url" {
  type        = string
  description = "Proxmox API endpoint (e.g. https://10.0.0.1:8006)"
}

variable "proxmox_api_token" {
  type        = string
  sensitive   = true
  description = "API token in format: user@realm!token_name=secret"
}

variable "proxmox_node" {
  type        = string
  default     = "pve"
  description = "Name of the Proxmox node"
}

# ─── VM Template ─────────────────────────────────────────

variable "template_id" {
  type        = number
  default     = 9000
  description = "VM ID of the golden image template"
}

# ─── SSH ─────────────────────────────────────────────────

variable "ssh_public_key" {
  type        = string
  description = "SSH public key to inject via Cloud-Init"
}
