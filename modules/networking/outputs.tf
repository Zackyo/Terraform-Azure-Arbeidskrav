# =============================================================================
# MODUL: networking/outputs.tf
# Eksponerer subnett-ID-er og VNet-ID for bruk i andre moduler
# =============================================================================

output "vnet_id" {
  description = "Ressurs-ID for Virtual Network"
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "Navn på Virtual Network"
  value       = azurerm_virtual_network.main.name
}

output "web_subnet_id" {
  description = "Ressurs-ID for web-lagets subnett"
  value       = azurerm_subnet.web.id
}

output "web_subnet_name" {
  description = "Navn på web-lagets subnett"
  value       = azurerm_subnet.web.name
}

output "db_subnet_id" {
  description = "Ressurs-ID for database-lagets subnett"
  value       = azurerm_subnet.db.id
}

output "db_subnet_name" {
  description = "Navn på database-lagets subnett"
  value       = azurerm_subnet.db.name
}
