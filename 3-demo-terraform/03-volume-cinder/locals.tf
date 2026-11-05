# Conventions de nommage de la démo
locals {
  prefix = "demo3"

  vm_name     = "${local.prefix}-vm"
  key_name    = "${local.prefix}-key"
  port_name   = "${local.prefix}-port"
  volume_name = "${local.prefix}-volume"
}
