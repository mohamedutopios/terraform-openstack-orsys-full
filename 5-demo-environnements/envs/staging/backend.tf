# L'état de CET environnement. Un backend ne peut pas utiliser de variables,
# d'où un backend.tf par dossier d'environnement.
#
# Ici : backend local (le lab n'offre pas de backend distant utilisable).
# En production on utiliserait un backend distant avec verrouillage et une
# clé PAR environnement, par exemple :
#
#   backend "s3" {
#     bucket = "mon-etat-terraform"
#     key    = "dev/terraform.tfstate"      <- distinct par env !
#     region = "eu-west-1"
#   }
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
