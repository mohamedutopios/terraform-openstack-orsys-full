# Entrées du module compute

variable "name" {
  description = "Nom de base : la VM, le port et la keypair en dérivent"
  type        = string
}

variable "image_name" {
  description = "Image Glance de la VM"
  type        = string
}

variable "flavor_name" {
  description = "Flavor de la VM"
  type        = string
}

variable "public_key" {
  description = "Contenu de la clé publique SSH (pas le chemin)"
  type        = string
}

variable "network_id" {
  description = "Réseau où brancher la VM"
  type        = string
}

variable "subnet_id" {
  description = "Sous-réseau pour l'IP fixe"
  type        = string
}

variable "security_group_ids" {
  description = "Security groups appliqués au port"
  type        = list(string)
}

variable "create_floating_ip" {
  description = "Associer une IP flottante à la VM"
  type        = bool
  default     = false
}

variable "floating_pool" {
  description = "Réseau externe fournissant l'IP flottante"
  type        = string
  default     = ""
}

variable "user_data" {
  description = "cloud-init optionnel"
  type        = string
  default     = null
}
