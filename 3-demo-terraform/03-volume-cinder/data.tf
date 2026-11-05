# Ressources existantes du lab (lecture seule)

data "openstack_networking_network_v2" "private" {
  name = var.network_name
}

data "openstack_networking_subnet_v2" "private" {
  name = var.subnet_name
}

data "openstack_networking_secgroup_v2" "ssh_icmp" {
  name = var.secgroup_name
}
