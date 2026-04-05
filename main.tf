# =============================================================================
# ROOT MAIN — orkestrerer alle moduler
# Dataflyt: networking → security → load-balancer → compute
# =============================================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.90"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "azurerm" {
  features {
    virtual_machine {
      delete_os_disk_on_deletion = true
      graceful_shutdown          = false
    }
  }
}

# ── Resource Group ────────────────────────────────────────────────────────────
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# ── Modul: networking ─────────────────────────────────────────────────────────
module "networking" {
  source = "./modules/networking"

  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  project_name        = var.project_name
  environment         = var.environment
  vnet_address_space  = var.vnet_address_space
  web_subnet_cidr     = var.web_subnet_cidr
  db_subnet_cidr      = var.db_subnet_cidr
  tags                = var.tags
}

# ── Modul: security ───────────────────────────────────────────────────────────
module "security" {
  source = "./modules/security"

  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  project_name        = var.project_name
  environment         = var.environment
  web_subnet_id       = module.networking.web_subnet_id
  db_subnet_id        = module.networking.db_subnet_id
  web_subnet_cidr     = var.web_subnet_cidr
  db_subnet_cidr      = var.db_subnet_cidr
  tags                = var.tags
}

# ── Modul: load-balancer ──────────────────────────────────────────────────────
# Oppretter intern Load Balancer for DB-laget
module "load_balancer" {
  source = "./modules/load-balancer"

  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  project_name        = var.project_name
  environment         = var.environment
  db_subnet_id        = module.networking.db_subnet_id
  tags                = var.tags
}

# ── Modul: compute ────────────────────────────────────────────────────────────
# Oppretter web-VM og DB-VM-er
module "compute" {
  source = "./modules/compute"

  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  project_name        = var.project_name
  environment         = var.environment
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  web_vm_size         = var.web_vm_size
  db_vm_size          = var.db_vm_size
  vm_image            = var.vm_image
  web_subnet_id       = module.networking.web_subnet_id
  db_subnet_id        = module.networking.db_subnet_id
  lb_backend_pool_id  = module.load_balancer.backend_pool_id
  mysql_root_password = var.mysql_root_password
  mysql_database_name = var.mysql_database_name
  mysql_app_user      = var.mysql_app_user
  mysql_app_password  = var.mysql_app_password
  db_lb_private_ip    = module.load_balancer.private_ip_address
  tags                = var.tags

  depends_on = [module.security]
}