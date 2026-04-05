# =============================================================================
# MODUL: security/outputs.tf
# =============================================================================

output "web_nsg_id" {
  description = "Ressurs-ID for NSG til web-laget"
  value       = azurerm_network_security_group.web.id
}

output "db_nsg_id" {
  description = "Ressurs-ID for NSG til DB-laget"
  value       = azurerm_network_security_group.db.id
}
