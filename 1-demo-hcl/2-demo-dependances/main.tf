variable "app_version" {

  type        = string
  default     = "2.1"
  description = "Version de l'application"
}

variable "db_trigger_var" {
  type        = string
  default     = "nouvelle valeur"
  description = "Variable utilisée pour le declenchement de la ressource DB"

}
resource "null_resource" "network" {
  triggers = {
    network = "net-001"
  }

}


resource "null_resource" "server" {
  triggers = {
    network_linked = null_resource.network.triggers["network"]
  }

}

resource "null_resource" "web_app" {
  depends_on = [null_resource.server]
  triggers = {
    version = var.app_version
  }

}


demo
