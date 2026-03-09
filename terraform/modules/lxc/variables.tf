variable "container_name" {
  type        = string
  description = "Name/hostname of the LXC container"
}

variable "vm_id" {
  type        = number
  description = "Proxmox container ID"
}

variable "target_node" {
  type        = string
  description = "Proxmox node to deploy on"
}

variable "os_template" {
  type        = string
  description = "LXC template (e.g. local:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst)"
}

variable "cores" {
  type    = number
  default = 1
}

variable "memory" {
  type        = number
  default     = 512
  description = "Memory in MB"
}

variable "disk" {
  type        = number
  default     = 8
  description = "Root disk size in GB"
}

variable "storage_pool" {
  type    = string
  default = "local-lvm"
}

variable "bridge" {
  type    = string
  default = "vmbr0"
}

variable "ip_address" {
  type        = string
  description = "Static IP in CIDR notation (e.g. 10.0.0.20/24)"
}

variable "gateway" {
  type    = string
  default = "10.0.0.1"
}

variable "dns_servers" {
  type    = list(string)
  default = ["8.8.8.8", "8.8.4.4"]
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key for the container"
}

variable "tags" {
  type    = list(string)
  default = []
}
