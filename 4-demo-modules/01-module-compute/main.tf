resource "openstack_networking_network_v2" "net" {
  name = local.net_name
}

resource "openstack_networking_subnet_v2" "subnet" {
  name            = local.subnet_name
  network_id      = openstack_networking_network_v2.net.id
  cidr            = var.subnet_cidr
  ip_version      = 4
  dns_nameservers = var.dns_nameservers
}

resource "openstack_networking_router_v2" "router" {
  name                = local.router_name
  external_network_id = data.openstack_networking_network_v2.public.id
}

resource "openstack_networking_router_interface_v2" "iface" {
  router_id = openstack_networking_router_v2.router.id
  subnet_id = openstack_networking_subnet_v2.subnet.id
}


resource "openstack_networking_secgroup_v2" "sg" {
  name        = local.sg_name
  description = "Demo modules 1 : SSH et ICMP"
}

resource "openstack_networking_secgroup_rule_v2" "ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.sg.id
}

resource "openstack_networking_secgroup_rule_v2" "icmp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.sg.id
}

module "vm" {
  source = "./modules/compute"

  name               = local.vm_name
  image_name         = var.image_name
  flavor_name        = var.flavor_name
  public_key         = file(pathexpand(var.public_key_path))
  network_id         = openstack_networking_network_v2.net.id
  subnet_id          = openstack_networking_subnet_v2.subnet.id
  security_group_ids = [openstack_networking_secgroup_v2.sg.id]

  create_floating_ip = true
  floating_pool      = var.external_network_name

  depends_on = [openstack_networking_router_interface_v2.iface]
}
