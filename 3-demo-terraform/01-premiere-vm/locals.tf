# Valeurs calculées / conventions de nommage
locals {
  prefix = "demo1"

  # Nom complet de chaque ressource : demo1-vm, demo1-port, ...
  vm_name   = "${local.prefix}-vm"
  key_name  = "${local.prefix}-key"
  port_name = "${local.prefix}-port"
}
