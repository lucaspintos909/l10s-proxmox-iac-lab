variable "proxmox_api_url" {
  description = "URL de la API de Proxmox"
  type        = string
}

variable "proxmox_api_token_id" {
  description = "ID del token API (ej: root@pam!terraform)"
  type        = string
}

variable "proxmox_api_token_secret" {
  description = "Secret del token API"
  type        = string
  sensitive   = true
}

variable "proxmox_node" {
  description = "Nodo de Proxmox donde desplegar el LXC"
  type        = string
  default     = "pve"
}

variable "ssh_public_key" {
  description = "Clave pública SSH para acceso root al LXC"
  type        = string
}

variable "lxc_root_password" {
  description = "Contraseña del usuario root del LXC"
  type        = string
  sensitive   = true
}
