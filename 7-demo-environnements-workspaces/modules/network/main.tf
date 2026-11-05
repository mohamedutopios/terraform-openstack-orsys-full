# Module network : réseau + sous-réseau + routeur raccordé au réseau externe

resource "openstack_networking_network_v2" "this" {
  name = "${var.name}-net"
}

resource "openstack_networking_subnet_v2" "this" {
  name            = "${var.name}-subnet"
  network_id      = openstack_networking_network_v2.this.id
  cidr            = var.cidr
  ip_version      = 4
  dns_nameservers = var.dns_nameservers
}

resource "openstack_networking_router_v2" "this" {
  name                = "${var.name}-router"
  external_network_id = var.external_network_id
}

resource "openstack_networking_router_interface_v2" "this" {
  router_id = openstack_networking_router_v2.this.id
  subnet_id = openstack_networking_subnet_v2.this.id
}
