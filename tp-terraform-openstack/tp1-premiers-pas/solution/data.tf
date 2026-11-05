# Le réseau externe existe déjà : on le référence, on ne le crée pas.
data "openstack_networking_network_v2" "public" {
  name = var.external_network_name
}
