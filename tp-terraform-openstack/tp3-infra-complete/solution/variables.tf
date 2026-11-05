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

variable "public_subnet_cidr" {
  description = "CIDR de public-subnet1 (réseau de VM1)"
  type        = string
}

variable "private_subnet_cidr" {
  description = "CIDR de private-subnet2 (réseau de VM2)"
  type        = string
}

variable "dns_nameservers" {
  description = "DNS annoncés par le DHCP"
  type        = list(string)
}

variable "image_url_bionic" {
  description = "URL de l'image cloud Ubuntu 18.04"
  type        = string
}

variable "image_url_jammy" {
  description = "URL de l'image cloud Ubuntu 22.04"
  type        = string
}

variable "flavor_vcpus" {
  description = "vCPUs du flavor"
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
