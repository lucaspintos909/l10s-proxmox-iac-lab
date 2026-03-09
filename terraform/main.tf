# ─── Docker Host VM ──────────────────────────────────────

module "docker_host" {
  source = "./modules/vm"

  vm_name     = "docker-host"
  vm_id       = 100
  target_node = var.proxmox_node
  template_id = var.template_id

  cores  = 4
  memory = 8192
  disk   = 40

  ip_address     = "10.0.0.10/24"
  gateway        = "10.0.0.1"
  dns_servers    = ["8.8.8.8", "8.8.4.4"]
  ssh_public_key = var.ssh_public_key

  tags = ["docker", "production"]
}

# ─── Monitoring LXC ─────────────────────────────────────

module "monitoring" {
  source = "./modules/lxc"

  container_name = "monitoring"
  vm_id          = 200
  target_node    = var.proxmox_node

  cores  = 1
  memory = 1024
  disk   = 8

  ip_address     = "10.0.0.20/24"
  gateway        = "10.0.0.1"
  dns_servers    = ["8.8.8.8", "8.8.4.4"]
  ssh_public_key = var.ssh_public_key

  os_template = "local:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"

  tags = ["monitoring"]
}
