# Déclaration des variables (les valeurs sont dans terraform.tfvars)

variable "cloud_name" {
  description = "Nom de l'entrée dans clouds.yaml"
  type        = string
  default     = "kolla-aio"
}

variable "container_name" {
  description = "Nom du conteneur Swift"
  type        = string
  default     = "demo4-conteneur"
}
