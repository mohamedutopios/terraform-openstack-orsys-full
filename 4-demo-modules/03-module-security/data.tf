data "openstack_networking_network_v2" "public" {
  name = var.external_network_name
}
