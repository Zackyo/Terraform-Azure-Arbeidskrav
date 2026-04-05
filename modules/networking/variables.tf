# =============================================================================
# MODUL: networking/variables.tf
# Lokalt scope: nettverksspesifikk konfigurasjon
# =============================================================================

variable "location" {
  description = "Azure-region"
  type        = string
}

variable "resource_group_name" {
  description = "Navn på resource group"
  type        = string
}

variable "project_name" {
  description = "Prosjektprefiks"
  type        = string
}

variable "environment" {
  description = "Utrullingsmiljø"
  type        = string
}

variable "vnet_address_space" {
  description = "VNet address space"
  type        = list(string)
}

variable "web_subnet_cidr" {
  description = "Web tier subnet CIDR"
  type        = string
}

variable "db_subnet_cidr" {
  description = "Database tier subnet CIDR"
  type        = string
}

variable "tags" {
  description = "Felles ressurstagger"
  type        = map(string)
}
