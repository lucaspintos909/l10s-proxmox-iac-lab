variable "vm_name" {
  type        = string
  description = "Name of the VM"
}

variable "vm_id" {
  type        = number
  description = "Proxmox VM ID"
}

variable "target_node" {
  type        = string
  description = "Proxmox node to deploy on"
}

variable "template_id" {
  type        = number
  description = "VM ID of the template to clone"
}

variable "cores" {
  type    = number
  default = 2
}

variable "memory" {
  type        = number
  default     = 2048
  description = "Memory in MB"
}

variable "disk" {
  type        = number
  default     = 20
  description = "Disk size in GB"
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
  description = "Static IP in CIDR notation (e.g. 10.0.0.10/24)"
}

variable "gateway" {
  type    = string
  default = "10.0.0.1"
}

variable "dns_servers" {
  type    = list(string)
  default = ["8.8.8.8", "8.8.4.4"]
}

variable "ci_user" {
  type    = string
  default = "ubuntu"
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key for Cloud-Init"
}

variable "tags" {
  type    = list(string)
  default = []
}
