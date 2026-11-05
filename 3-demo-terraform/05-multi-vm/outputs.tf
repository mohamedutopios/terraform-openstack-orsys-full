# Sorties affichées après `terraform apply`

output "vms" {
  description = "Nom -> IP privée de chaque VM"
  value = {
    for i, vm in openstack_compute_instance_v2.vm :
    vm.name => openstack_networking_port_v2.vm[i].all_fixed_ips[0]
  }
}
