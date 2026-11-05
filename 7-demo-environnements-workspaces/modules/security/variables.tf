# Entrées du module security

variable "name" {
  description = "Nom du security group"
  type        = string
}

variable "description" {
  description = "Description du security group"
  type        = string
  default     = "Géré par Terraform"
}

# Une règle = un objet. port_min/port_max inutiles pour icmp,
# remote_ip_prefix vaut 0.0.0.0/0 par défaut : optional() gère tout ça.
variable "rules" {
  description = "Règles ingress à créer"
  type = list(object({
    protocol         = string
    port_min         = optional(number)
    port_max         = optional(number)
    remote_ip_prefix = optional(string, "0.0.0.0/0")
  }))
}
