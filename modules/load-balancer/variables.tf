# =============================================================================
# MODUL: load-balancer/variables.tf
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

variable "db_subnet_id" {
  description = "ID til DB-subnettet der ILB-frontend ligger"
  type        = string
}

# ── Lokal variabel: privat ILB-IP ───────────────────────────────────────────
# Dette er et lokalt ansvar — kun denne modulen håndterer LB-frontend-IP-en.
variable "lb_private_ip" {
  description = "Statisk privat IP for frontend på intern Load Balancer (må ligge innenfor db_subnet_cidr)"
  type        = string
  default     = "10.0.2.10"
}

variable "tags" {
  description = "Felles ressurstagger"
  type        = map(string)
}
