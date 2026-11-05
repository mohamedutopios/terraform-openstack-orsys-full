# Démo 3 — Volume Cinder
# Une VM avec un volume de stockage bloc créé et attaché par Terraform.
# Le volume apparaît comme /dev/vdb dans la VM (backend LVM du lab).

resource "openstack_compute_keypair_v2" "demo" {
  name       = local.key_name
  public_key = file(pathexpand(var.public_key_path))
}

resource "openstack_networking_port_v2" "vm" {
  name               = local.port_name
  network_id         = data.openstack_networking_network_v2.private.id
  security_group_ids = [data.openstack_networking_secgroup_v2.ssh_icmp.id]

  fixed_ip {
    subnet_id = data.openstack_networking_subnet_v2.private.id
  }
}

resource "openstack_compute_instance_v2" "vm" {
  name        = local.vm_name
  image_name  = var.image_name
  flavor_name = var.flavor_name
  key_pair    = openstack_compute_keypair_v2.demo.name

  network {
    port = openstack_networking_port_v2.vm.id
  }
}

# --- Volume Cinder attaché à la VM ---
resource "openstack_blockstorage_volume_v3" "data" {
  name        = local.volume_name
  description = "Volume de demonstration (backend LVM)"
  size        = var.volume_size_gb
}

resource "openstack_compute_volume_attach_v2" "attach" {
  instance_id = openstack_compute_instance_v2.vm.id
  volume_id   = openstack_blockstorage_volume_v3.data.id
}
