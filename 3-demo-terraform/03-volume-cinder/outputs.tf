# Sorties affichées après `terraform apply`

output "volume_id" {
  description = "Identifiant du volume Cinder"
  value       = openstack_blockstorage_volume_v3.data.id
}

output "peripherique" {
  description = "Chemin du disque vu par la VM"
  value       = openstack_compute_volume_attach_v2.attach.device
}

output "ip_privee" {
  description = "IP de la VM sur le réseau privé"
  value       = openstack_networking_port_v2.vm.all_fixed_ips[0]
}
