output "environnement" {
  description = "Environnement de cet état"
  value       = var.environment
}

output "message" {
  description = "Message de l'environnement"
  value       = var.message
}

output "marqueur_id" {
  description = "ID du null_resource (change si les triggers changent)"
  value       = null_resource.marqueur.id
}
