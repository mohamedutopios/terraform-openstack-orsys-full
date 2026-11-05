# Démo backend GitLab — null_resource : aucune vraie infrastructure,
# uniquement la mécanique Terraform (état distant, verrouillage, triggers).

resource "null_resource" "marqueur" {
  # Les triggers déterminent QUAND la ressource est recréée : si l'un
  # de ces champs change entre deux apply, la ressource est remplacée.
  triggers = {
    environment = var.environment
    message     = var.message
    test = var.test
  }

  # S'exécute sur la machine qui lance terraform, à la création
  provisioner "local-exec" {
    command = "echo [${var.environment}] ${var.message} - ${var.test}"
  }
}
