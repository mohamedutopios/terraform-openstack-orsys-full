# Uniquement ce qui est COMMUN aux environnements.
# Ce qui varie d'un environnement à l'autre est dans locals.tf (map envs).

variable "cloud_name" {
  description = "Nom de l'entrée dans clouds.yaml"
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

variable "external_network_name" {
  description = "Réseau externe existant"
  type        = string
}

variable "dns_nameservers" {
  description = "DNS annoncés par le DHCP"
  type        = list(string)
}
