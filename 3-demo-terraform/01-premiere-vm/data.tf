# Ressources existantes référencées en lecture seule.
# Le sous-réseau est nécessaire pour le fixed_ip du port explicite (main.tf).

data "openstack_networking_network_v2" "private" {
  name = var.network_name
}

data "openstack_networking_subnet_v2" "private" {
  name = var.subnet_name
}

data "openstack_networking_secgroup_v2" "ssh_icmp" {
  name = var.secgroup_name
}
