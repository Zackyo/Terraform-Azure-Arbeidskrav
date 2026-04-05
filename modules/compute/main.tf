# =============================================================================
# MODUL: compute/main.tf
# Oppretter:
#   - 1 Public IP + NIC + web-VM (web-subnett)
#   - 2 NIC-er + DB-VM-er        (db-subnett, koblet til ILB backend pool)
#
# Cloud-init:
#   Web VM → Nginx + Flask (kobler til MySQL via ILB)
#   DB VM-er → MySQL + schema + demodata
# =============================================================================

# ─────────────────────────────────────────────────────────────────────────────
# WEB-SERVER
# ─────────────────────────────────────────────────────────────────────────────

# Public IP for webserver (HTTP + SSH)
resource "azurerm_public_ip" "web" {
  name                = "${var.project_name}-${var.environment}-web-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# Web-NIC i web-subnett
resource "azurerm_network_interface" "web" {
  name                = "${var.project_name}-${var.environment}-web-nic"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  ip_configuration {
    name                          = "web-ipconfig"
    subnet_id                     = var.web_subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.web.id
  }
}

# Cloud-init for web-VM: installerer Nginx + Flask og kobler til DB via ILB
locals {
  web_custom_data = base64encode(templatefile("${path.module}/scripts/web-init.sh", {
    db_lb_ip            = var.db_lb_private_ip
    mysql_database_name = var.mysql_database_name
    mysql_app_user      = var.mysql_app_user
    mysql_app_password  = var.mysql_app_password
  }))

  # Lokale navn for DB-VM-er (brukes kun i denne modulen)
  db_vm_names = [
    "${var.project_name}-${var.environment}-db-vm-1",
    "${var.project_name}-${var.environment}-db-vm-2"
  ]
}

resource "azurerm_linux_virtual_machine" "web" {
  name                            = "${var.project_name}-${var.environment}-web-vm"
  location                        = var.location
  resource_group_name             = var.resource_group_name
  size                            = var.web_vm_size
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false
  custom_data                     = local.web_custom_data
  tags                            = var.tags

  network_interface_ids = [azurerm_network_interface.web.id]

  os_disk {
    name                 = "${var.project_name}-${var.environment}-web-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }

  source_image_reference {
    publisher = var.vm_image.publisher
    offer     = var.vm_image.offer
    sku       = var.vm_image.sku
    version   = var.vm_image.version
  }

  # Boot diagnostics for feilsøking av cloud-init
  boot_diagnostics {}
}

# ─────────────────────────────────────────────────────────────────────────────
# DATABASESERVERE (2 VM-er — kun intern tilgang)
# ─────────────────────────────────────────────────────────────────────────────

# DB-NIC-er i db-subnett, kobles til ILB backend pool
resource "azurerm_network_interface" "db" {
  count               = 2
  name                = "${var.project_name}-${var.environment}-db-nic-${count.index + 1}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  ip_configuration {
    name                          = "db-ipconfig"
    subnet_id                     = var.db_subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

# Koble DB-NIC-er til ILB backend pool
resource "azurerm_network_interface_backend_address_pool_association" "db" {
  count                   = 2
  network_interface_id    = azurerm_network_interface.db[count.index].id
  ip_configuration_name   = "db-ipconfig"
  backend_address_pool_id = var.lb_backend_pool_id
}

# Cloud-init for DB-VM: installerer MySQL, oppretter DB/bruker/tabell og legger inn demodata
resource "azurerm_linux_virtual_machine" "db" {
  count                           = 2
  name                            = local.db_vm_names[count.index]
  location                        = var.location
  resource_group_name             = var.resource_group_name
  size                            = var.db_vm_size
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false
  tags                            = var.tags

  custom_data = base64encode(templatefile("${path.module}/scripts/db-init.sh", {
    mysql_root_password = var.mysql_root_password
    mysql_database_name = var.mysql_database_name
    mysql_app_user      = var.mysql_app_user
    mysql_app_password  = var.mysql_app_password
    vm_index            = count.index + 1
  }))

  network_interface_ids = [azurerm_network_interface.db[count.index].id]

  os_disk {
    name                 = "${var.project_name}-${var.environment}-db-osdisk-${count.index + 1}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }

  source_image_reference {
    publisher = var.vm_image.publisher
    offer     = var.vm_image.offer
    sku       = var.vm_image.sku
    version   = var.vm_image.version
  }

  boot_diagnostics {}

  depends_on = [azurerm_network_interface_backend_address_pool_association.db]
}