# Chaque variable illustre UNE source de valeur possible.

# 1. Valeur par défaut : utilisée si RIEN d'autre ne la fournit
variable "var_defaut" {
  description = "Alimentée par son défaut uniquement"
  type        = string
  default     = "je viens du default de variables.tf"
}

# 2. Variable d'environnement : TF_VAR_var_env (pas de défaut -> obligatoire)
variable "var_env" {
  description = "Alimentée par la variable d'environnement TF_VAR_var_env"
  type        = string
}

# 3. terraform.tfvars : chargé AUTOMATIQUEMENT (son nom exact est magique)
variable "var_tfvars" {
  description = "Alimentée par terraform.tfvars"
  type        = string
}

# 4. *.auto.tfvars : chargés AUTOMATIQUEMENT, en ordre alphabétique
variable "var_auto" {
  description = "Alimentée par aaa.auto.tfvars"
  type        = string
}

# 5. -var / -var-file : fournie à la main sur la ligne de commande
variable "var_cli" {
  description = "À surcharger avec -var=\"var_cli=...\""
  type        = string
  default     = "(non surchargée : je retombe sur mon default)"
}

# LA variable vedette : définie PARTOUT à la fois, pour voir qui gagne.
# Elle a un défaut, une valeur dans terraform.tfvars, une dans
# aaa.auto.tfvars, une dans zzz.auto.tfvars... et vous pouvez ajouter
# TF_VAR_qui_gagne et -var pour compléter le tournoi.
variable "qui_gagne" {
  description = "Définie dans toutes les sources : la précédence tranche"
  type        = string
  default     = "1-le-default"
}
