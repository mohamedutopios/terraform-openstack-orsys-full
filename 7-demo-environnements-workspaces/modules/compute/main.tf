# Module compute : keypair + port + VM (+ IP flottante optionnelle)

resource "openstack_compute_keypair_v2" "this" {
  name       = "${var.name}-key"
  public_key = var.public_key
}

resource "openstack_networking_port_v2" "this" {
  name               = "${var.name}-port"
  network_id         = var.network_id
  security_group_ids = var.security_group_ids

  fixed_ip {
    subnet_id = var.subnet_id
  }
}

resource "openstack_compute_instance_v2" "this" {
  name        = var.name
  image_name  = var.image_name
  flavor_name = var.flavor_name
  key_pair    = openstack_compute_keypair_v2.this.name
  user_data   = var.user_data

  network {
    port = openstack_networking_port_v2.this.id
  }
}

# count sur un booléen : 1 ressource si create_floating_ip, sinon 0
resource "openstack_networking_floatingip_v2" "this" {
  count = var.create_floating_ip ? 1 : 0
  pool  = var.floating_pool
}

resource "openstack_networking_floatingip_associate_v2" "this" {
  count       = var.create_floating_ip ? 1 : 0
  floating_ip = openstack_networking_floatingip_v2.this[0].address
  port_id     = openstack_networking_port_v2.this.id
}
