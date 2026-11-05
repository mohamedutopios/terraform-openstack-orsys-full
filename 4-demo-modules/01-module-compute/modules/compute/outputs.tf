output "instance_id" {
  description = "ID de la VM"
  value       = openstack_compute_instance_v2.this.id
}

output "private_ip" {
  description = "IP fixe de la VM"
  value       = openstack_networking_port_v2.this.all_fixed_ips[0]
}

output "floating_ip" {
  description = "IP flottante (null si non demandée)"
  value       = var.create_floating_ip ? openstack_networking_floatingip_v2.this[0].address : null
}
