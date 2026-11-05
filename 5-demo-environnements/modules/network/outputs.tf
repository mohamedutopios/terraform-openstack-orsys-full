# Sorties du module network — consommées par le module compute

output "network_id" {
  description = "ID du réseau créé"
  value       = openstack_networking_network_v2.this.id
}

output "subnet_id" {
  description = "ID du sous-réseau créé"
  value       = openstack_networking_subnet_v2.this.id
}

output "router_interface_id" {
  description = "Interface routeur : permet de dépendre du seul raccordement (le stack utilise depends_on = [module.network])"
  value       = openstack_networking_router_interface_v2.this.id
}
