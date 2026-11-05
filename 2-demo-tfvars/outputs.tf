output "bilan_des_sources" {
  description = "Chaque variable et la source qui l'a réellement alimentée"
  value = {
    "1_var_defaut (default)"          = var.var_defaut
    "2_var_env (TF_VAR_var_env)"      = var.var_env
    "3_var_tfvars (terraform.tfvars)" = var.var_tfvars
    "4_var_auto (aaa.auto.tfvars)"    = var.var_auto
    "5_var_cli (-var)"                = var.var_cli
  }
}

output "qui_gagne" {
  description = "La valeur retenue pour la variable définie partout"
  value       = var.qui_gagne
}
