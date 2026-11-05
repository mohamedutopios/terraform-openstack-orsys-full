# Sorties affichées après `terraform apply`

output "reseau" {
  description = "Réseau créé et sa plage"
  value       = "${openstack_networking_network_v2.net.name} (${openstack_networking_subnet_v2.subnet.cidr})"
}

output "ip_privee" {
  description = "IP de la VM sur le réseau dédié"
  value       = openstack_networking_port_v2.vm.all_fixed_ips[0]
}

output "ip_flottante" {
  description = "IP joignable depuis la machine hôte"
  value       = openstack_networking_floatingip_v2.fip.address
}

output "ssh" {
  description = "Commande de connexion"
  value       = "ssh cirros@${openstack_networking_floatingip_v2.fip.address}  (mot de passe : gocubsgo)"
}
