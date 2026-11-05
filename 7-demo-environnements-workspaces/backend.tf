# UN seul backend pour tous les environnements : c'est le workspace qui
# sépare les états. Avec le backend local :
#   workspace "default" -> ./terraform.tfstate
#   workspace "dev"     -> ./terraform.tfstate.d/dev/terraform.tfstate
#   workspace "prod"    -> ./terraform.tfstate.d/prod/terraform.tfstate
#
# Tous les backends ne gèrent pas les workspaces : s3, azurerm, gcs, pg,
# consul... oui ; "http" (donc le backend GitLab) NON.
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
