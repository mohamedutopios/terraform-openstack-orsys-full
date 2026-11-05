locals {
  prefix = "tp2"

  net_name    = "${local.prefix}-net"
  subnet_name = "${local.prefix}-subnet"
  router_name = "${local.prefix}-router"
  sg_name     = "${local.prefix}-sg"
  key_name    = "${local.prefix}-key"
  port_name   = "${local.prefix}-port"
  vm_name     = "${local.prefix}-web"
  image_name  = "${local.prefix}-ubuntu-22.04"
  flavor_name = "${local.prefix}-flavor"
  volume_name = "${local.prefix}-data"

  # Rendu du cloud-init : les variables du template sont injectées ici
  user_data = templatefile("${path.module}/templates/user_data.yaml.tftpl", {
    student_name    = var.student_name
    welcome_message = var.welcome_message
    vm_name         = local.vm_name
  })
}
