# TP 1 — solution
# VM CirrOS sur un réseau privé dédié, joignable par IP flottante.

# --- Réseau privé + sous-réseau ---
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

# --- Raccordement au réseau externe : le routeur ---
resource "openstack_networking_router_v2" "router" {
  name                = local.router_name
  external_network_id = data.openstack_networking_network_v2.public.id
}

resource "openstack_networking_router_interface_v2" "iface" {
  router_id = openstack_networking_router_v2.router.id
  subnet_id = openstack_networking_subnet_v2.subnet.id
}

# --- Security group : SSH + ICMP uniquement ---
resource "openstack_networking_secgroup_v2" "sg" {
  name        = local.sg_name
  description = "TP1 : SSH et ICMP"
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

# --- Keypair ---
resource "openstack_compute_keypair_v2" "key" {
  name       = local.key_name
  public_key = file(pathexpand(var.public_key_path))
}

# --- VM ---
resource "openstack_networking_port_v2" "vm" {
  name               = local.port_name
  network_id         = openstack_networking_network_v2.net.id
  security_group_ids = [openstack_networking_secgroup_v2.sg.id]

  fixed_ip {
    subnet_id = openstack_networking_subnet_v2.subnet.id
  }
}

resource "openstack_compute_instance_v2" "vm" {
  name        = local.vm_name
  image_name  = var.image_name
  flavor_name = var.flavor_name
  key_pair    = openstack_compute_keypair_v2.key.name

  network {
    port = openstack_networking_port_v2.vm.id
  }

  depends_on = [openstack_networking_router_interface_v2.iface]
}

# --- IP flottante ---
resource "openstack_networking_floatingip_v2" "fip" {
  pool = var.external_network_name
}

resource "openstack_networking_floatingip_associate_v2" "fip" {
  floating_ip = openstack_networking_floatingip_v2.fip.address
  port_id     = openstack_networking_port_v2.vm.id

  # Neutron refuse l'association tant que le sous-réseau n'est pas routé vers public
  depends_on = [openstack_networking_router_interface_v2.iface]
}
