# Déclaration des variables (les valeurs sont dans terraform.tfvars)

variable "cloud_name" {
  description = "Nom de l'entrée dans clouds.yaml"
  type        = string
  default     = "openstack"
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
  description = "Gabarit (vCPU/RAM/disque) de la VM"
  type        = string
  default     = "m1.tiny"
}

variable "network_name" {
  description = "Réseau privé existant du lab"
  type        = string
  default     = "private"
}

variable "subnet_name" {
  description = "Sous-réseau du réseau privé"
  type        = string
  default     = "private-subnet"
}

variable "secgroup_name" {
  description = "Security group existant (SSH + ICMP)"
  type        = string
  default     = "allow-ssh-icmp"
}

variable "floating_pool" {
  description = "Réseau externe fournissant les IP flottantes"
  type        = string
  default     = "public"
}
