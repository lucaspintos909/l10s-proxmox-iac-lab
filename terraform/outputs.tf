# ─── Docker Host Outputs ─────────────────────────────────

output "docker_host_ip" {
  value       = module.docker_host.ip_address
  description = "IP address of the docker-host VM"
}

output "docker_host_id" {
  value       = module.docker_host.vm_id
  description = "Proxmox VM ID of the docker-host"
}

# ─── Monitoring LXC Outputs ─────────────────────────────

output "monitoring_ip" {
  value       = module.monitoring.ip_address
  description = "IP address of the monitoring LXC"
}

output "monitoring_id" {
  value       = module.monitoring.container_id
  description = "Proxmox container ID of the monitoring LXC"
}
