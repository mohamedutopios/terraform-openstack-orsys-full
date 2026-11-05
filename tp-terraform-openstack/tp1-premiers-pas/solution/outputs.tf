output "ip_privee" {
  description = "IP fixe de la VM sur le réseau privé"
  value       = openstack_networking_port_v2.vm.all_fixed_ips[0]
}

output "ip_flottante" {
  description = "IP flottante associée à la VM"
  value       = openstack_networking_floatingip_v2.fip.address
}

output "ssh" {
  description = "Commande de connexion"
  value       = "ssh cirros@${openstack_networking_floatingip_v2.fip.address}"
}
