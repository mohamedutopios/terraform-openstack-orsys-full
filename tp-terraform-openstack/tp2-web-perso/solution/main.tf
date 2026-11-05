# TP 2 — solution
# Image Glance + flavor créés par Terraform, VM Ubuntu 22.04 configurée par
# cloud-init (nginx + page personnalisée), volume attaché, IP flottante.

# --- Image Glance créée depuis l'URL officielle Ubuntu ---
resource "openstack_images_image_v2" "web" {
  name             = local.image_name
  image_source_url = var.image_url
  disk_format      = "qcow2"
  container_format = "bare"
  visibility       = "private"

  properties = {
    os_distro = "ubuntu"
  }
}

# --- Flavor sur mesure (admin) ---
resource "openstack_compute_flavor_v2" "flavor" {
  name  = local.flavor_name
  vcpus = var.flavor_vcpus
  ram   = var.flavor_ram_mb
  disk  = var.flavor_disk_gb
}

# --- Socle réseau ---
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

# --- Security group : HTTP + SSH + ICMP ---
resource "openstack_networking_secgroup_v2" "sg" {
  name        = local.sg_name
  description = "TP2 : HTTP, SSH, ICMP"
}

resource "openstack_networking_secgroup_rule_v2" "http" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.sg.id
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

# --- VM (image + flavor + cloud-init maison) ---
resource "openstack_networking_port_v2" "vm" {
  name               = local.port_name
  network_id         = openstack_networking_network_v2.net.id
  security_group_ids = [openstack_networking_secgroup_v2.sg.id]

  fixed_ip {
    subnet_id = openstack_networking_subnet_v2.subnet.id
  }
}

resource "openstack_compute_instance_v2" "vm" {
  name      = local.vm_name
  image_id  = openstack_images_image_v2.web.id
  flavor_id = openstack_compute_flavor_v2.flavor.id
  key_pair  = openstack_compute_keypair_v2.key.name
  user_data = local.user_data

  network {
    port = openstack_networking_port_v2.vm.id
  }

  depends_on = [openstack_networking_router_interface_v2.iface]
}

# --- Volume de données attaché ---
resource "openstack_blockstorage_volume_v3" "data" {
  name = local.volume_name
  size = var.volume_size_gb
}

resource "openstack_compute_volume_attach_v2" "attach" {
  instance_id = openstack_compute_instance_v2.vm.id
  volume_id   = openstack_blockstorage_volume_v3.data.id
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
