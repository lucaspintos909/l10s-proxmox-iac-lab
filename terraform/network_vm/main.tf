module "traefik_vm" {
  source = "../modules/proxmox_vm"

  name          = "traefik-edge"
  node_name     = var.proxmox_node
  description   = "VM de Gestión - Traefik y Cloudflared (DMZ + Internal)"
  vm_id         = 100
  template_vmid = 9000
  
  cpu_cores = 2
  memory    = 2048
  disk_size = 20

  ssh_username   = var.ssh_username
  ssh_public_key = var.ssh_public_key

  network_interfaces = [
    {
      bridge  = "vmbr1"
      address = "10.0.0.10/24"
      gateway = "10.0.0.1"
    },
    {
      bridge  = "vmbr2"
      address = "10.1.0.10/24"
      gateway = null
    }
  ]
}

output "traefik_vm_ips" {
  description = "Direcciones IP de la VM Traefik"
  value       = module.traefik_vm.ipv4_addresses
}
