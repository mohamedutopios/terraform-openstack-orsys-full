locals {
  prefix = "tp3"

  net_public_name     = "${local.prefix}-network-public"
  subnet_public_name  = "${local.prefix}-public-subnet1"
  net_private_name    = "${local.prefix}-network-private"
  subnet_private_name = "${local.prefix}-private-subnet2"
  router_name         = "${local.prefix}-router"
  sg_vm1_name         = "${local.prefix}-sg-vm1-web"
  sg_vm2_name         = "${local.prefix}-sg-vm2-private"
  key_name            = "${local.prefix}-key"
  flavor_name         = "${local.prefix}-flavor"
  image_bionic_name   = "${local.prefix}-ubuntu-18.04"
  image_jammy_name    = "${local.prefix}-ubuntu-22.04"
  vm1_name            = "${local.prefix}-vm1-nginx"
  vm2_name            = "${local.prefix}-vm2"

  # cloud-init de VM1 : installation nginx (robuste aux dépôts EOL de bionic)
  vm1_user_data = templatefile("${path.module}/templates/vm1_nginx.yaml.tftpl", {
    vm_name = local.vm1_name
  })
}
