terraform {
  required_version = ">= 1.5"

  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }

  # Configuration PARTIELLE du backend : le bloc est déclaré vide, les
  # paramètres arrivent au moment du init :
  #   terraform init -reconfigure -backend-config=backends/dev.hcl
  # C'est ce qui permet UN code et TROIS backends (un état par env).
  backend "http" {}
}
