variable "name" {
  description = "Nombre de la VM"
  type        = string
}

variable "node_name" {
  description = "Nodo de Proxmox donde correr la VM"
  type        = string
  default     = "pve"
}

variable "vm_id" {
  description = "ID opcional de la VM"
  type        = number
  default     = null
}

variable "description" {
  description = "Descripción de la VM"
  type        = string
  default     = "Manageada por Terraform"
}

variable "tags" {
  description = "Tags de la VM"
  type        = list(string)
  default     = []
}

variable "cpu_cores" {
  description = "Cores de CPU"
  type        = number
  default     = 2
}

variable "memory" {
  description = "RAM en MB"
  type        = number
  default     = 2048
}

variable "disk_size" {
  description = "Tamaño del disco en GB"
  type        = number
  default     = 20
}

variable "datastore_id" {
  description = "Datastore donde crear el disco"
  type        = string
  default     = "local-lvm"
}

variable "template_vmid" {
  description = "ID del template de Packer a clonar"
  type        = number
}

variable "network_interfaces" {
  description = "Lista de interfaces de red"
  type = list(object({
    bridge  = string
    address = string
    gateway = optional(string)
  }))
}

variable "ssh_username" {
  description = "Usuario admin"
  type        = string
}

variable "ssh_public_key" {
  description = "Clave pública SSH"
  type        = string
}
