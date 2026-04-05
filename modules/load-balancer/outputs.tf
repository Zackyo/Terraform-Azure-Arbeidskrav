# =============================================================================
# MODUL: load-balancer/outputs.tf
# Eksporterer backend pool-ID og ILB IP til compute-modulen
# =============================================================================

output "lb_id" {
  description = "Ressurs-ID for intern Load Balancer"
  value       = azurerm_lb.db.id
}

output "backend_pool_id" {
  description = "Backend pool-ID — DB-VMenes NIC-er kobles til her"
  value       = azurerm_lb_backend_address_pool.db.id
}

output "private_ip_address" {
  description = "Statisk privat IP for ILB — web-server kobler til denne på port 3306"
  value       = azurerm_lb.db.frontend_ip_configuration[0].private_ip_address
}

output "probe_id" {
  description = "Ressurs-ID for helseprobe"
  value       = azurerm_lb_probe.mysql.id
}