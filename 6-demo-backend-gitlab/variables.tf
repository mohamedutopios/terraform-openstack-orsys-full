variable "environment" {
  description = "Nom de l'environnement (dev, staging, prod)"
  type        = string
}

variable "message" {
  description = "Message propre à l'environnement"
  type        = string
}


variable "test" {
  type = bool

}