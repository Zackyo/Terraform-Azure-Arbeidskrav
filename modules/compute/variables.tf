# =============================================================================
# MODUL: compute/variables.tf
# =============================================================================

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "admin_username" {
  description = "Administratorbruker for VM"
  type        = string
}

variable "admin_password" {
  description = "Administratorpassord for VM"
  type        = string
  sensitive   = true
}

variable "web_vm_size" {
  description = "VM-størrelse for webserver"
  type        = string
}

variable "db_vm_size" {
  description = "VM-størrelse for database"
  type        = string
}

variable "vm_image" {
  description = "Felles OS-image for alle VM-er"
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
}

variable "web_subnet_id" {
  description = "Subnett-ID for webserver (fra networking-modul)"
  type        = string
}

variable "db_subnet_id" {
  description = "Subnett-ID for database-VM-er (fra networking-modul)"
  type        = string
}

variable "lb_backend_pool_id" {
  description = "Backend pool-ID for ILB — DB-NIC-er kobles til her (fra load-balancer-modul)"
  type        = string
}

variable "db_lb_private_ip" {
  description = "Privat IP for ILB — web-applikasjon kobler til denne (fra load-balancer-modul)"
  type        = string
}

variable "mysql_root_password" {
  description = "MySQL root-passord"
  type        = string
  sensitive   = true
}

variable "mysql_database_name" {
  description = "Navn på MySQL-database"
  type        = string
}

variable "mysql_app_user" {
  description = "MySQL applikasjonsbruker"
  type        = string
}

variable "mysql_app_password" {
  description = "Passord for MySQL applikasjonsbruker"
  type        = string
  sensitive   = true
}

variable "tags" {
  type = map(string)
}