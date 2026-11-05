# Déclaration des variables (les valeurs sont dans terraform.tfvars)

variable "cloud_name" {
  description = "Nom de l'entrée dans clouds.yaml"
  type        = string
  default     = "kolla-aio"
}

variable "vm_count" {
  description = "Nombre de VMs à déployer"
  type        = number
  default     = 2

  validation {
    condition     = var.vm_count >= 1 && var.vm_count <= 5
    error_message = "vm_count doit être entre 1 et 5 (lab avec ressources limitées)."
  }
}

variable "public_key_path" {
  description = "Chemin de la clé publique SSH injectée dans les VMs"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "image_name" {
  description = "Image Glance utilisée pour les VMs"
  type        = string
  default     = "cirros"
}

variable "flavor_name" {
  description = "Gabarit des VMs"
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
