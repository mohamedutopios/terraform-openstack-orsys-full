# Le préfixe n'est défini qu'ici : tous les noms en dérivent.
locals {
  prefix = "tp1"

  net_name    = "${local.prefix}-net"
  subnet_name = "${local.prefix}-subnet"
  router_name = "${local.prefix}-router"
  sg_name     = "${local.prefix}-sg"
  key_name    = "${local.prefix}-key"
  port_name   = "${local.prefix}-port"
  vm_name     = "${local.prefix}-vm"
}
