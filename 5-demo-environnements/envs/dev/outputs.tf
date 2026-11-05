# Ré-exposition des sorties du stack
output "environnement" {
  value = module.stack.environnement
}

output "ip_privee" {
  value = module.stack.ip_privee
}

output "ip_flottante" {
  value = module.stack.ip_flottante
}

output "ssh" {
  value = module.stack.ssh
}
