# Démo tfvars — un null_resource qui matérialise d'où vient chaque valeur.
# Si une source change, le trigger correspondant change -> la ressource
# est REMPLACÉE et le local-exec réaffiche le bilan.

resource "null_resource" "bilan" {
  triggers = {
    var_defaut = var.var_defaut
    var_env    = var.var_env
    var_tfvars = var.var_tfvars
    var_auto   = var.var_auto
    var_cli    = var.var_cli
    qui_gagne  = var.qui_gagne
  }

  provisioner "local-exec" {
    command = "echo QUI GAGNE : ${var.qui_gagne}"
  }
}
