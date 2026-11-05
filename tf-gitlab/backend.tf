terraform {
  required_version = ">= 1.6.0"

  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 3.0"
    }
  }

  # GitLab-managed Terraform state.
  # Address, lock, credentials : fournis par les variables d'environnement TF_HTTP_*
  # (en local via export, en CI via .gitlab-ci.yml) — aucun secret dans le code.
  backend "http" {}
}

# Authentification OpenStack lue dans les variables d'environnement OS_*
provider "openstack" {}
