# Démo 5 — Plusieurs VMs avec count
# Déploie N VMs identiques (variable vm_count) sur le réseau private.
# Montre count, les variables, les locals en compréhension de liste et les
# outputs calculés. Pas d'IP flottantes pour rester léger.

resource "openstack_compute_keypair_v2" "demo" {
  name       = local.key_name
  public_key = file(pathexpand(var.public_key_path))
}

resource "openstack_networking_port_v2" "vm" {
  count              = var.vm_count
  name               = local.port_names[count.index]
  network_id         = data.openstack_networking_network_v2.private.id
  security_group_ids = [data.openstack_networking_secgroup_v2.ssh_icmp.id]

  fixed_ip {
    subnet_id = data.openstack_networking_subnet_v2.private.id
  }
}

resource "openstack_compute_instance_v2" "vm" {
  count       = var.vm_count
  name        = local.vm_names[count.index]
  image_name  = var.image_name
  flavor_name = var.flavor_name
  key_pair    = openstack_compute_keypair_v2.demo.name

  network {
    port = openstack_networking_port_v2.vm[count.index].id
  }
}
