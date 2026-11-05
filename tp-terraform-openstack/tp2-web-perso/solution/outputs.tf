output "ip_flottante" {
  description = "IP flottante de la VM"
  value       = openstack_networking_floatingip_v2.fip.address
}

output "url" {
  description = "URL de la page web personnalisée"
  value       = "http://${openstack_networking_floatingip_v2.fip.address}"
}

output "volume_peripherique" {
  description = "Périphérique du volume vu par la VM"
  value       = openstack_compute_volume_attach_v2.attach.device
}

output "ssh" {
  description = "Commande de connexion"
  value       = "ssh ubuntu@${openstack_networking_floatingip_v2.fip.address}"
}
