# Entrées du stack : TOUT ce qui peut varier entre environnements.
# Une différence entre dev et prod = une variable ici, rien d'autre.

variable "environment" {
  description = "Nom de l'environnement (préfixe de toutes les ressources)"
  type        = string
}

variable "public_key_path" {
  description = "Chemin de la clé publique SSH"
  type        = string
}

variable "image_name" {
  description = "Image de la VM"
  type        = string
}

variable "flavor_name" {
  description = "Flavor de la VM"
  type        = string
}

variable "external_network_name" {
  description = "Réseau externe existant"
  type        = string
}

variable "subnet_cidr" {
  description = "CIDR du sous-réseau de l'environnement"
  type        = string
}

variable "dns_nameservers" {
  description = "DNS annoncés par le DHCP"
  type        = list(string)
}

variable "ssh_allowed_cidr" {
  description = "Plage autorisée à se connecter en SSH"
  type        = string
}
