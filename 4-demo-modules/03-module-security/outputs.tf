# Le root re-expose les sorties du module

output "ip_privee" {
  description = "IP fixe de la VM"
  value       = module.vm.private_ip
}

output "ip_flottante" {
  description = "IP flottante de la VM"
  value       = module.vm.floating_ip
}

output "ssh" {
  description = "Commande de connexion"
  value       = "ssh cirros@${module.vm.floating_ip}"
}
