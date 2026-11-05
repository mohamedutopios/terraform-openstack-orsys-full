# Déclaration des variables (les valeurs sont dans terraform.tfvars)

variable "cloud_name" {
  description = "Nom de l'entrée dans clouds.yaml"
  type        = string
  default     = "kolla-aio"
}

variable "public_key_path" {
  description = "Chemin de la clé publique SSH injectée dans la VM"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "image_name" {
  description = "Image Glance utilisée pour la VM"
  type        = string
  default     = "cirros"
}

variable "flavor_name" {
  description = "Gabarit de la VM"
  type        = string
  default     = "m1.tiny"
}

variable "external_network_name" {
  description = "Réseau externe existant (passerelle du routeur + IP flottantes)"
  type        = string
  default     = "public"
}

variable "subnet_cidr" {
  description = "Plage IP du sous-réseau dédié"
  type        = string
  default     = "10.20.0.0/24"
}

variable "dns_nameservers" {
  description = "Serveurs DNS annoncés par le DHCP du sous-réseau"
  type        = list(string)
  default     = ["8.8.8.8"]
}
