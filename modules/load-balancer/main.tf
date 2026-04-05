# =============================================================================
# MODUL: load-balancer/main.tf
# Intern Azure Load Balancer — fordeler MySQL-trafikk mellom DB-VM-er
#
# Helseprobe overvåker port 3306.
# LB-regel bruker TCP uten session persistence (round-robin).
# =============================================================================

# ── Privat IP (statisk) for ILB frontend ─────────────────────────────────────
resource "azurerm_lb" "db" {
  name                = "${var.project_name}-${var.environment}-db-ilb"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"
  tags                = var.tags

  frontend_ip_configuration {
    name                          = "db-frontend"
    subnet_id                     = var.db_subnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.lb_private_ip # 10.0.2.10
  }
}

# ── Backend pool ──────────────────────────────────────────────────────────────
resource "azurerm_lb_backend_address_pool" "db" {
  name            = "${var.project_name}-db-backend-pool"
  loadbalancer_id = azurerm_lb.db.id
}

# ── Helseprobe (MySQL, port 3306) ─────────────────────────────────────────────
# Sjekk hvert 15. sekund, markerer node som utilgjengelig etter 2 feil.
# Trafikk sendes kun til tilgjengelige DB-noder.
resource "azurerm_lb_probe" "mysql" {
  name                = "mysql-health-probe"
  loadbalancer_id     = azurerm_lb.db.id
  protocol            = "Tcp"
  port                = 3306
  interval_in_seconds = 15
  number_of_probes    = 2
}

# ── Lastbalanseringsregel ─────────────────────────────────────────────────────
resource "azurerm_lb_rule" "mysql" {
  name                           = "mysql-lb-rule"
  loadbalancer_id                = azurerm_lb.db.id
  protocol                       = "Tcp"
  frontend_port                  = 3306
  backend_port                   = 3306
  frontend_ip_configuration_name = "db-frontend"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.db.id]
  probe_id                       = azurerm_lb_probe.mysql.id
  load_distribution              = "Default" # round-robin
  idle_timeout_in_minutes        = 4
  enable_floating_ip             = false
  disable_outbound_snat          = true
}