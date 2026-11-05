# Le STACK : la composition commune aux trois environnements, écrite UNE fois.
# Corriger ce fichier corrige dev, staging et prod (chacun à son prochain apply).

locals {
  prefix  = var.environment
  vm_name = "${local.prefix}-vm"
}

data "openstack_networking_network_v2" "public" {
  name = var.external_network_name
}

module "network" {
  source = "../modules/network"

  name                = local.prefix
  cidr                = var.subnet_cidr
  dns_nameservers     = var.dns_nameservers
  external_network_id = data.openstack_networking_network_v2.public.id
}

module "security" {
  source = "../modules/security"

  name        = "${local.prefix}-sg"
  description = "SSH (${var.ssh_allowed_cidr}) et ICMP - ${var.environment}"

  rules = [
    { protocol = "tcp", port_min = 22, port_max = 22, remote_ip_prefix = var.ssh_allowed_cidr },
    { protocol = "icmp" },
  ]
}

module "vm" {
  source = "../modules/compute"

  name               = local.vm_name
  image_name         = var.image_name
  flavor_name        = var.flavor_name
  public_key         = file(pathexpand(var.public_key_path))
  network_id         = module.network.network_id
  subnet_id          = module.network.subnet_id
  security_group_ids = [module.security.sg_id]

  create_floating_ip = true
  floating_pool      = var.external_network_name

  depends_on = [module.network]
}
