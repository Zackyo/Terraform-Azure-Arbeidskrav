# =============================================================================
# MODUL: security/main.tf
# Oppretter NSG-er for web- og DB-subnett etter prinsippet om minste privilegium.
#
# Web-NSG:
#   Inngående: HTTP(80), HTTPS(443), SSH(22) fra Internet
#   Utgående: MySQL(3306) kun til DB-subnett
#
# DB-NSG:
#   Inngående: MySQL(3306) kun fra web-subnett
#   Inngående: SSH(22) fra web-subnett via jump host
#   Avviser all annen inngående trafikk
# =============================================================================

# ── NSG for web-lag ───────────────────────────────────────────────────────────
resource "azurerm_network_security_group" "web" {
  name                = "${var.project_name}-${var.environment}-web-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  # Tillat HTTP fra Internet
  security_rule {
    name                       = "Allow-HTTP-Inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  # Tillat HTTPS fra Internet
  security_rule {
    name                       = "Allow-HTTPS-Inbound"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  # Tillat SSH for administrasjon
  # I produksjon bør denne begrenses til faste IP-adresser
  security_rule {
    name                       = "Allow-SSH-Inbound"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  # Avvis all annen inngående trafikk
  security_rule {
    name                       = "Deny-All-Inbound"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Tillat utgående MySQL-trafikk til DB-subnett
  security_rule {
    name                       = "Allow-MySQL-To-DB-Subnet"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3306"
    source_address_prefix      = "*"
    destination_address_prefix = var.db_subnet_cidr
  }

  # Tillat utgående HTTPS for pakkeinstallasjon
  security_rule {
    name                       = "Allow-HTTPS-Outbound"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }

  # Tillat utgående HTTP for pakkearkiv
  security_rule {
    name                       = "Allow-HTTP-Outbound"
    priority                   = 120
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }
}

# ── NSG for database-lag ──────────────────────────────────────────────────────
resource "azurerm_network_security_group" "db" {
  name                = "${var.project_name}-${var.environment}-db-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  # Tillat MySQL kun fra web-subnett
  security_rule {
    name                       = "Allow-MySQL-From-Web-Subnet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3306"
    source_address_prefix      = var.web_subnet_cidr
    destination_address_prefix = "*"
  }

  # Tillat MySQL fra lastbalansererens helseprobe
  security_rule {
    name                       = "Allow-LB-HealthProbe"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3306"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }

  # Tillat SSH fra web-subnett via jump host
  security_rule {
    name                       = "Allow-SSH-From-Web-Subnet"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.web_subnet_cidr
    destination_address_prefix = "*"
  }

  # Avvis all annen inngående trafikk
  # Databaseserverne er ikke eksponert mot Internet
  security_rule {
    name                       = "Deny-All-Inbound"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Tillat utgående HTTPS for pakkeoppdateringer
  security_rule {
    name                       = "Allow-HTTPS-Outbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }

  # Tillat utgående HTTP for pakkearkiv
  security_rule {
    name                       = "Allow-HTTP-Outbound"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }
}

# ── Knytt NSG til web-subnett ──────────────────────────────────────────────────
resource "azurerm_subnet_network_security_group_association" "web" {
  subnet_id                 = var.web_subnet_id
  network_security_group_id = azurerm_network_security_group.web.id
}

# ── Knytt NSG til DB-subnett ───────────────────────────────────────────────────
resource "azurerm_subnet_network_security_group_association" "db" {
  subnet_id                 = var.db_subnet_id
  network_security_group_id = azurerm_network_security_group.db.id
}