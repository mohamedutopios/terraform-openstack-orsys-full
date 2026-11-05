locals {
  prefix = "dm1"

  net_name    = "${local.prefix}-net"
  subnet_name = "${local.prefix}-subnet"
  router_name = "${local.prefix}-router"
  sg_name     = "${local.prefix}-sg"
  vm_name     = "${local.prefix}-vm"
}
