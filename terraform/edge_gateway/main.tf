module "traefik_vm" {
  source = "../modules/proxmox_vm"

  name          = "traefik-edge"
  node_name     = var.proxmox_node
  description   = "VM de Gestión - Traefik y Cloudflared"
  vm_id         = 100
  template_vmid = 9000
  
  cpu_cores = 2
  memory    = 2048
  disk_size = 20

  ssh_username   = var.ssh_username
  ssh_public_key = var.ssh_public_key

  network_interfaces = [
    {
      bridge  = "vmbr0"          # DMZ (Salida a internet)
      address = "10.0.0.10/24"   # IP correcta para vmbr0
      gateway = "10.0.0.1"       # Su única puerta de salida al mundo
    },
    {
      bridge  = "vmbr1"          # Red de Proyectos
      address = "10.1.0.10/24"   # IP correcta para vmbr1
      gateway = null             # SIN gateway para evitar ruteo asimétrico
    },
    {
      bridge  = "vmbr2"          # Red de Herramientas
      address = "10.2.0.10/24"   # IP correcta para vmbr2
      gateway = null             # SIN gateway
    }
  ]
}