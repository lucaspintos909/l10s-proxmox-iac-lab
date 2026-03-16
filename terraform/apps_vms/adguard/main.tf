module "adguard_vm" {
  source = "../../modules/proxmox_vm"

  name          = "adguard-dns"
  node_name     = var.proxmox_node
  description   = "AdGuard Home - Split-Brain DNS (Red Interna)"
  vm_id         = 101
  template_vmid = 9000

  cpu_cores = 1
  memory    = 1024
  disk_size = 20

  ssh_username   = var.ssh_username
  ssh_public_key = var.ssh_public_key

  network_interfaces = [
    {
      bridge  = "vmbr2"
      address = "10.2.0.11/24"
      gateway = "10.2.0.1"
    }
  ]
}

output "adguard_vm_id" {
  value = module.adguard_vm.vm_id
}

output "adguard_vm_ips" {
  value = module.adguard_vm.ipv4_addresses
}
