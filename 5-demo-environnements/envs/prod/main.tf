# L'environnement ne fait QU'appeler le stack commun avec ses valeurs.
# La différence entre dev, staging et prod vit dans terraform.tfvars.
module "stack" {
  source = "../../stack"

  environment           = var.environment
  public_key_path       = var.public_key_path
  image_name            = var.image_name
  flavor_name           = var.flavor_name
  external_network_name = var.external_network_name
  subnet_cidr           = var.subnet_cidr
  dns_nameservers       = var.dns_nameservers
  ssh_allowed_cidr      = var.ssh_allowed_cidr
}
