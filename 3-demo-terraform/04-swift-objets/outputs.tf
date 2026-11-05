# Sorties affichées après `terraform apply`

output "conteneur" {
  description = "Nom du conteneur Swift créé"
  value       = openstack_objectstorage_container_v1.bucket.name
}

output "objets" {
  description = "Objets stockés dans le conteneur"
  value = [
    openstack_objectstorage_object_v1.bonjour.name,
    openstack_objectstorage_object_v1.fichier.name,
  ]
}

output "verification" {
  description = "Commande à lancer dans la VM pour lister le conteneur"
  value       = "openstack object list ${openstack_objectstorage_container_v1.bucket.name}"
}
