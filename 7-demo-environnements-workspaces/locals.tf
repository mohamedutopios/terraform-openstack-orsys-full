# LA différence entre les environnements : une entrée par workspace.
# terraform.workspace vaut le nom du workspace sélectionné
# (terraform workspace select dev) : c'est lui qui choisit la ligne.

locals {
  envs = {
    dev = {
      subnet_cidr      = "10.60.1.0/24"
      flavor_name      = "m1.tiny"
      ssh_allowed_cidr = "0.0.0.0/0"
    }
    staging = {
      subnet_cidr      = "10.60.2.0/24"
      flavor_name      = "m1.tiny"
      ssh_allowed_cidr = "0.0.0.0/0"
    }
    prod = {
      subnet_cidr = "10.60.3.0/24"
      # m1.small visé, m1.tiny pour tenir dans le disque du lab
      flavor_name      = "m1.tiny"
      ssh_allowed_cidr = "192.168.57.0/24"
    }
  }

  # Pas d'entrée pour "default" : la garde de main.tf bloque le plan.
  # Le repli sur "dev" sert seulement à ce que validate (qui tourne dans
  # "default") puisse évaluer le code ; rien n'est jamais créé avec.
  known_workspace = contains(keys(local.envs), terraform.workspace)
  env             = local.envs[local.known_workspace ? terraform.workspace : "dev"]

  # "ws-" évite toute collision avec la version par dossiers (dev-vm-key...)
  prefix  = "ws-${terraform.workspace}"
  vm_name = "${local.prefix}-vm"
}
