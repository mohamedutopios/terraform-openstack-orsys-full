output "vm1_ip_flottante" {
  description = "IP flottante de VM1"
  value       = openstack_networking_floatingip_v2.vm1.address
}

output "vm1_url" {
  description = "Page nginx par défaut de VM1"
  value       = "http://${openstack_networking_floatingip_v2.vm1.address}"
}

output "vm1_ip_privee" {
  description = "IP de VM1 sur network-public"
  value       = openstack_networking_port_v2.vm1.all_fixed_ips[0]
}

output "vm2_ip_privee" {
  description = "IP de VM2 sur network-private"
  value       = openstack_networking_port_v2.vm2.all_fixed_ips[0]
}

output "test_ping" {
  description = "À lancer depuis VM1 pour valider le routage inter-réseaux"
  value       = "ssh ubuntu@${openstack_networking_floatingip_v2.vm1.address} puis : ping -c 3 ${openstack_networking_port_v2.vm2.all_fixed_ips[0]}"
}
