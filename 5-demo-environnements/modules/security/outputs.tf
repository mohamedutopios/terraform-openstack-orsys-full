output "sg_id" {
  description = "ID du security group créé"
  value       = openstack_networking_secgroup_v2.this.id
}

output "rule_keys" {
  description = "Clés des règles créées (visualise le for_each)"
  value       = keys(openstack_networking_secgroup_rule_v2.this)
}
