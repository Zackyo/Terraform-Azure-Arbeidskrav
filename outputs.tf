# =============================================================================
# ROOT OUTPUTS — eksponerer nøkkelverdier etter utrulling
# =============================================================================

output "resource_group_name" {
  description = "Navn på den utrullede Resource Group"
  value       = azurerm_resource_group.main.name
}

output "web_vm_public_ip" {
  description = "Offentlig IP-adresse til webserveren (SSH- og HTTP-tilgang)"
  value       = module.compute.web_vm_public_ip
}

output "web_service_url" {
  description = "URL for å nå webapplikasjonen"
  value       = "http://${module.compute.web_vm_public_ip}"
}

output "db_vm_private_ips" {
  description = "Private IP-adresser til de to database-VM-ene"
  value       = module.compute.db_vm_private_ips
}

output "internal_lb_private_ip" {
  description = "Privat IP til intern Load Balancer (brukes av webserveren)"
  value       = module.load_balancer.private_ip_address
}

output "vnet_id" {
  description = "Ressurs-ID for Virtual Network"
  value       = module.networking.vnet_id
}

output "ssh_web_command" {
  description = "SSH-kommando for å koble til webserveren"
  value       = "ssh ${var.admin_username}@${module.compute.web_vm_public_ip}"
}

output "web_nsg_id" {
  description = "NSG brukt på web-subnettet"
  value       = module.security.web_nsg_id
}

output "db_nsg_id" {
  description = "NSG brukt på databasesubnettet"
  value       = module.security.db_nsg_id
}
