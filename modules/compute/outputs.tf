# =============================================================================
# MODUL: compute/outputs.tf
# =============================================================================

output "web_vm_public_ip" {
  description = "Offentlig IP-adresse til webserver-VM-en"
  value       = azurerm_public_ip.web.ip_address
}

output "web_vm_private_ip" {
  description = "Privat IP-adresse til webserveren"
  value       = azurerm_network_interface.web.private_ip_address
}

output "web_vm_id" {
  description = "Ressurs-ID for web-VM-en"
  value       = azurerm_linux_virtual_machine.web.id
}

output "db_vm_private_ips" {
  description = "Liste over private IP-adresser for de to database-VM-ene"
  value       = azurerm_network_interface.db[*].private_ip_address
}

output "db_vm_ids" {
  description = "Liste over ressurs-ID-er for database-VM-ene"
  value       = azurerm_linux_virtual_machine.db[*].id
}

output "db_vm_names" {
  description = "Liste over navn på database-VM-ene"
  value       = azurerm_linux_virtual_machine.db[*].name
}
