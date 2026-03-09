output "container_id" {
  value       = proxmox_virtual_environment_container.lxc.vm_id
  description = "The Proxmox container ID"
}

output "ip_address" {
  value       = var.ip_address
  description = "The static IP assigned to this container"
}

output "name" {
  value       = var.container_name
  description = "The container hostname"
}
