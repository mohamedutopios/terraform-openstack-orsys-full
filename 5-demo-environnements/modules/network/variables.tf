# Entrées du module network

variable "name" {
  description = "Nom de base : réseau, sous-réseau et routeur en dérivent"
  type        = string
}

variable "cidr" {
  description = "CIDR du sous-réseau"
  type        = string
}

variable "dns_nameservers" {
  description = "DNS annoncés par le DHCP"
  type        = list(string)
  default     = ["8.8.8.8"]
}

variable "external_network_id" {
  description = "ID du réseau externe (passerelle du routeur)"
  type        = string
}
