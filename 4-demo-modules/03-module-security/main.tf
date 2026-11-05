# Démo modules 3 — tout est modulaire : network + security + compute.
# Le root ne fait plus que COMPOSER les modules : c'est l'aboutissement
# de la démarche commencée en démo 1.

module "network" {
  source = "./modules/network"

  name                = local.prefix
  cidr                = var.subnet_cidr
  dns_nameservers     = var.dns_nameservers
  external_network_id = data.openstack_networking_network_v2.public.id
}

module "security" {
  source = "./modules/security"

  name        = "${local.prefix}-sg"
  description = "Demo modules 3 : SSH et ICMP"

  # Les règles sont des données : une liste d'objets, pas des ressources
  # répétées à la main. Le module les déploie avec for_each.
  rules = [
    { protocol = "tcp", port_min = 22, port_max = 22 },
    { protocol = "icmp" },
  ]
}

module "vm" {
  source = "./modules/compute"

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
