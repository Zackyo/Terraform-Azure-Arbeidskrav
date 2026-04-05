# =============================================================================
# GLOBALE VARIABLER
# Definert en gang her og brukt på tvers av networking-, compute- og
# load-balancer-modulene. Lokale/modulspesifikke variabler ligger i hver moduls egen variables.tf.
# =============================================================================

variable "location" {
  description = "Azure-region for alle ressurser"
  type        = string
  default     = "West Europe"
}

variable "resource_group_name" {
  description = "Navn på Azure Resource Group"
  type        = string
  default     = "rg-webdb-project"
}

variable "project_name" {
  description = "Kort prosjektidentifikator brukt som prefiks for alle ressursnavn"
  type        = string
  default     = "webdb"
}

variable "environment" {
  description = "Tag for utrullingsmiljø (dev / staging / prod)"
  type        = string
  default     = "dev"
}

# ── Nettverk ──────────────────────────────────────────────────────────────────
variable "vnet_address_space" {
  description = "Adresseområde for Virtual Network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "web_subnet_cidr" {
  description = "CIDR-blokk for web-lagets subnett"
  type        = string
  default     = "10.0.1.0/24"
}

variable "db_subnet_cidr" {
  description = "CIDR-blokk for database-lagets subnett"
  type        = string
  default     = "10.0.2.0/24"
}

# ── Compute ───────────────────────────────────────────────────────────────────
variable "admin_username" {
  description = "Administratorbrukernavn for alle VM-er"
  type        = string
  default     = "azureuser"
}

variable "admin_password" {
  description = "Administratorpassord for alle VM-er (bruk Key Vault i produksjon)"
  type        = string
  sensitive   = true
  default     = "P@ssw0rd1234!"
}

variable "web_vm_size" {
  description = "VM-SKU for webserveren"
  type        = string
  default     = "Standard_B2s"
}

variable "db_vm_size" {
  description = "VM-SKU for databaseserverne"
  type        = string
  default     = "Standard_B2s"
}

variable "vm_image" {
  description = "Ubuntu image-referanse som deles av alle VM-er"
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  default = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}

# ── Database ──────────────────────────────────────────────────────────────────
variable "mysql_root_password" {
  description = "Root-passord for MySQL"
  type        = string
  sensitive   = true
  default     = "MySQLR00t!Pass"
}

variable "mysql_database_name" {
  description = "Navn på demodatabasen"
  type        = string
  default     = "appdb"
}

variable "mysql_app_user" {
  description = "Applikasjonsbruker for MySQL"
  type        = string
  default     = "appuser"
}

variable "mysql_app_password" {
  description = "Passord for MySQL-applikasjonsbrukeren"
  type        = string
  sensitive   = true
  default     = "AppUser!Pass123"
}

# ── Tagger ────────────────────────────────────────────────────────────────────
variable "tags" {
  description = "Felles tagger som brukes på alle ressurser"
  type        = map(string)
  default = {
    Project     = "webdb-project"
    Environment = "dev"
    ManagedBy   = "Terraform"
    Owner       = "fiverr-client"
  }
}
