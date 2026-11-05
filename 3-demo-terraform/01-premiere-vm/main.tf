# Démo 1 — Première VM (version AVEC port explicite)
# Le port Neutron est créé par Terraform avant l'instance : on choisit le
# sous-réseau (et éventuellement l'IP fixe), les security groups sont posés
# sur le port (par ID), et l'IP flottante est associée au port via l'API
# networking. Le port survit à la recréation de l'instance : même IP privée.

resource "openstack_compute_keypair_v2" "demo" {
  name       = "demo1-key"
  public_key = file(pathexpand(var.public_key_path))
}

resource "openstack_networking_port_v2" "vm" {
  name               = "demo1-port"
  network_id         = data.openstack_networking_network_v2.private.id
  admin_state_up     = true
  security_group_ids = [data.openstack_networking_secgroup_v2.ssh_icmp.id]

  fixed_ip {
    subnet_id = data.openstack_networking_subnet_v2.private.id
    # ip_address = "192.168.10.50"   # IP fixe éventuelle
  }
}

resource "openstack_compute_instance_v2" "vm" {
  name        = "demo1-vm"
  image_name  = var.image_name
  flavor_name = var.flavor_name
  key_pair    = openstack_compute_keypair_v2.demo.name
  # pas de security_groups ici : ils sont portés par le port

  network {
    port = openstack_networking_port_v2.vm.id
  }
}

resource "openstack_networking_floatingip_v2" "fip" {
  pool = var.floating_pool
}

# Variante networking de l'association (port_id au lieu de instance_id)
resource "openstack_networking_floatingip_associate_v2" "fip" {
  floating_ip = openstack_networking_floatingip_v2.fip.address
  port_id     = openstack_networking_port_v2.vm.id
}
