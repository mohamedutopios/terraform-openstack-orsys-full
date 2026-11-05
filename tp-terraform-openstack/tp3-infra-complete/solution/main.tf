# TP 3 — solution
# Deux réseaux + un routeur, deux images Ubuntu, un flavor, deux VMs :
# VM1 (18.04, nginx, IP flottante) sur network-public,
# VM2 (22.04) sur network-private, ping VM1 -> VM2 via le routeur.

# --- Images Glance ---
resource "openstack_images_image_v2" "bionic" {
  name             = local.image_bionic_name
  image_source_url = var.image_url_bionic
  disk_format      = "qcow2"
  container_format = "bare"
  visibility       = "private"

  properties = {
    os_distro = "ubuntu"
  }
}

resource "openstack_images_image_v2" "jammy" {
  name             = local.image_jammy_name
  image_source_url = var.image_url_jammy
  disk_format      = "qcow2"
  container_format = "bare"
  visibility       = "private"

  properties = {
    os_distro = "ubuntu"
  }
}

# --- Flavor 2 vCPU / 2048 Mo / 10 Go (admin) ---
resource "openstack_compute_flavor_v2" "flavor" {
  name  = local.flavor_name
  vcpus = var.flavor_vcpus
  ram   = var.flavor_ram_mb
  disk  = var.flavor_disk_gb
}

# --- network-public / public-subnet1 ---
resource "openstack_networking_network_v2" "net_public" {
  name = local.net_public_name
}

resource "openstack_networking_subnet_v2" "subnet_public" {
  name            = local.subnet_public_name
  network_id      = openstack_networking_network_v2.net_public.id
  cidr            = var.public_subnet_cidr
  ip_version      = 4
  dns_nameservers = var.dns_nameservers
}

# --- network-private / private-subnet2 ---
resource "openstack_networking_network_v2" "net_private" {
  name = local.net_private_name
}

resource "openstack_networking_subnet_v2" "subnet_private" {
  name            = local.subnet_private_name
  network_id      = openstack_networking_network_v2.net_private.id
  cidr            = var.private_subnet_cidr
  ip_version      = 4
  dns_nameservers = var.dns_nameservers
}

# --- Un seul routeur, trois pattes : externe + les deux sous-réseaux ---
resource "openstack_networking_router_v2" "router" {
  name                = local.router_name
  external_network_id = data.openstack_networking_network_v2.public.id
}

resource "openstack_networking_router_interface_v2" "iface_public" {
  router_id = openstack_networking_router_v2.router.id
  subnet_id = openstack_networking_subnet_v2.subnet_public.id
}

resource "openstack_networking_router_interface_v2" "iface_private" {
  router_id = openstack_networking_router_v2.router.id
  subnet_id = openstack_networking_subnet_v2.subnet_private.id
}

# --- Security groups (un par rôle) ---
resource "openstack_networking_secgroup_v2" "vm1" {
  name        = local.sg_vm1_name
  description = "TP3 VM1 : HTTP, SSH, ICMP"
}

resource "openstack_networking_secgroup_rule_v2" "vm1_http" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.vm1.id
}

resource "openstack_networking_secgroup_rule_v2" "vm1_ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.vm1.id
}

resource "openstack_networking_secgroup_rule_v2" "vm1_icmp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.vm1.id
}

resource "openstack_networking_secgroup_v2" "vm2" {
  name        = local.sg_vm2_name
  description = "TP3 VM2 : ICMP + SSH depuis le reseau public"
}

resource "openstack_networking_secgroup_rule_v2" "vm2_icmp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.vm2.id
}

resource "openstack_networking_secgroup_rule_v2" "vm2_ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = var.public_subnet_cidr
  security_group_id = openstack_networking_secgroup_v2.vm2.id
}

# --- Keypair ---
resource "openstack_compute_keypair_v2" "key" {
  name       = local.key_name
  public_key = file(pathexpand(var.public_key_path))
}

# --- VM1 : Ubuntu 18.04 + nginx, sur network-public, IP flottante ---
resource "openstack_networking_port_v2" "vm1" {
  name               = "${local.vm1_name}-port"
  network_id         = openstack_networking_network_v2.net_public.id
  security_group_ids = [openstack_networking_secgroup_v2.vm1.id]

  fixed_ip {
    subnet_id = openstack_networking_subnet_v2.subnet_public.id
  }
}

resource "openstack_compute_instance_v2" "vm1" {
  name      = local.vm1_name
  image_id  = openstack_images_image_v2.bionic.id
  flavor_id = openstack_compute_flavor_v2.flavor.id
  key_pair  = openstack_compute_keypair_v2.key.name
  user_data = local.vm1_user_data

  network {
    port = openstack_networking_port_v2.vm1.id
  }

  depends_on = [openstack_networking_router_interface_v2.iface_public]
}

resource "openstack_networking_floatingip_v2" "vm1" {
  pool = var.external_network_name
}

resource "openstack_networking_floatingip_associate_v2" "vm1" {
  floating_ip = openstack_networking_floatingip_v2.vm1.address
  port_id     = openstack_networking_port_v2.vm1.id

  # Neutron refuse l'association tant que le sous-réseau n'est pas routé vers public
  depends_on = [openstack_networking_router_interface_v2.iface_public]
}

# --- VM2 : Ubuntu 22.04, sur network-private, pas d'IP flottante ---
resource "openstack_networking_port_v2" "vm2" {
  name               = "${local.vm2_name}-port"
  network_id         = openstack_networking_network_v2.net_private.id
  security_group_ids = [openstack_networking_secgroup_v2.vm2.id]

  fixed_ip {
    subnet_id = openstack_networking_subnet_v2.subnet_private.id
  }
}

resource "openstack_compute_instance_v2" "vm2" {
  name      = local.vm2_name
  image_id  = openstack_images_image_v2.jammy.id
  flavor_id = openstack_compute_flavor_v2.flavor.id
  key_pair  = openstack_compute_keypair_v2.key.name

  network {
    port = openstack_networking_port_v2.vm2.id
  }

  depends_on = [openstack_networking_router_interface_v2.iface_private]
}
