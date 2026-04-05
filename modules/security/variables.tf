# =============================================================================
# MODUL: security/variables.tf
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

variable "web_subnet_id" {
  description = "ID til web-lagets subnett (fra output i networking-modulen)"
  type        = string
}

variable "db_subnet_id" {
  description = "ID til DB-lagets subnett (fra output i networking-modulen)"
  type        = string
}

variable "web_subnet_cidr" {
  description = "CIDR for web-subnettet — brukes i kilde-regler i DB-NSG"
  type        = string
}

variable "db_subnet_cidr" {
  description = "CIDR for DB-subnettet — brukes i destinasjonsregler i web-NSG"
  type        = string
}

variable "tags" {
  type = map(string)
}
