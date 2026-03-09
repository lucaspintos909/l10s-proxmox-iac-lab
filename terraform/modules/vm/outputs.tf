output "vm_id" {
  value       = proxmox_virtual_environment_vm.vm.vm_id
  description = "The Proxmox VM ID"
}

output "ip_address" {
  value       = var.ip_address
  description = "The static IP assigned to this VM"
}

output "name" {
  value       = proxmox_virtual_environment_vm.vm.name
  description = "The VM name"
}
