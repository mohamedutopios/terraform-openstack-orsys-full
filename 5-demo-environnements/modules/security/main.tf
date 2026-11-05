# Module security : un security group + ses règles pilotées par les données

resource "openstack_networking_secgroup_v2" "this" {
  name        = var.name
  description = var.description
}

# for_each exige une map : on construit une clé lisible par règle
# (ex. "tcp-22-22", "icmp--")
resource "openstack_networking_secgroup_rule_v2" "this" {
  for_each = {
    for r in var.rules :
    "${r.protocol}-${coalesce(r.port_min, 0)}-${coalesce(r.port_max, 0)}" => r
  }

  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = each.value.protocol
  port_range_min    = each.value.port_min
  port_range_max    = each.value.port_max
  remote_ip_prefix  = each.value.remote_ip_prefix
  security_group_id = openstack_networking_secgroup_v2.this.id
}
