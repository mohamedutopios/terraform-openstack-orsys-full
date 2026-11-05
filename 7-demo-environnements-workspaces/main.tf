# Même infrastructure que 5-demo-environnements (réseau + security group +
# VM CirrOS avec IP flottante), mais UN seul dossier : l'environnement est
# choisi par le workspace sélectionné, pas par le dossier où l'on se trouve.

# Garde-fou : refuse de planifier dans un workspace inconnu (dont "default"),
# sinon on créerait un environnement "ws-default" par simple oubli.
resource "terraform_data" "workspace_guard" {
  input = terraform.workspace

  lifecycle {
    precondition {
      condition     = local.known_workspace
      error_message = "Workspace \"${terraform.workspace}\" inconnu : faites terraform workspace select dev | staging | prod."
    }
  }
}

data "openstack_networking_network_v2" "public" {
  name = var.external_network_name
}

module "network" {
  source = "./modules/network"

  name                = local.prefix
  cidr                = local.env.subnet_cidr
  dns_nameservers     = var.dns_nameservers
  external_network_id = data.openstack_networking_network_v2.public.id

  depends_on = [terraform_data.workspace_guard]
}

module "security" {
  source = "./modules/security"

  name        = "${local.prefix}-sg"
  description = "SSH (${local.env.ssh_allowed_cidr}) et ICMP - ${terraform.workspace}"

  rules = [
    { protocol = "tcp", port_min = 22, port_max = 22, remote_ip_prefix = local.env.ssh_allowed_cidr },
    { protocol = "icmp" },
  ]

  depends_on = [terraform_data.workspace_guard]
}

module "vm" {
  source = "./modules/compute"

  name               = local.vm_name
  image_name         = var.image_name
  flavor_name        = local.env.flavor_name
  public_key         = file(pathexpand(var.public_key_path))
  network_id         = module.network.network_id
  subnet_id          = module.network.subnet_id
  security_group_ids = [module.security.sg_id]

  create_floating_ip = true
  floating_pool      = var.external_network_name

  # L'IP flottante ne s'associe qu'une fois le sous-réseau routé vers public
  depends_on = [module.network]
}
