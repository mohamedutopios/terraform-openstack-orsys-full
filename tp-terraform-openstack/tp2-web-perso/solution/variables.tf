variable "cloud_name" {
  description = "Nom de l'entrée dans clouds.yaml (admin requis pour le flavor)"
  type        = string
}

variable "public_key_path" {
  description = "Chemin de la clé publique SSH"
  type        = string
}

variable "external_network_name" {
  description = "Réseau externe existant (IP flottantes)"
  type        = string
}

variable "subnet_cidr" {
  description = "CIDR du sous-réseau privé"
  type        = string
}

variable "dns_nameservers" {
  description = "DNS annoncés par le DHCP"
  type        = list(string)
}

variable "image_url" {
  description = "URL de l'image cloud Ubuntu 22.04"
  type        = string
}

variable "flavor_vcpus" {
  description = "Nombre de vCPUs du flavor"
  type        = number
}

variable "flavor_ram_mb" {
  description = "RAM du flavor en Mo"
  type        = number
}

variable "flavor_disk_gb" {
  description = "Disque du flavor en Go"
  type        = number
}

variable "volume_size_gb" {
  description = "Taille du volume de données en Go"
  type        = number
}

variable "student_name" {
  description = "Nom affiché sur la page web"
  type        = string
}

variable "welcome_message" {
  description = "Message affiché sur la page web"
  type        = string
}
