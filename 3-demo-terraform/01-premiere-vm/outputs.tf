# Sorties affichées après `terraform apply`

output "ip_privee" {
  description = "IP de la VM sur le réseau privé"
  value       = openstack_compute_instance_v2.vm.network[0].fixed_ip_v4
}

output "ip_flottante" {
  description = "IP joignable depuis la machine hôte"
  value       = openstack_networking_floatingip_v2.fip.address
}

output "ssh" {
  description = "Commande de connexion"
  value       = "ssh cirros@${openstack_networking_floatingip_v2.fip.address}  (mot de passe : gocubsgo)"
}
