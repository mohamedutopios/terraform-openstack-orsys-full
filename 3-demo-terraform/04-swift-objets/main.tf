# Démo 4 — Stockage objet Swift
# Un conteneur Swift avec deux objets : un créé depuis du contenu inline,
# l'autre depuis un fichier local. Aucune VM : Swift est un service à part.

resource "openstack_objectstorage_container_v1" "bucket" {
  name     = var.container_name
  metadata = local.metadata
}

# Objet créé depuis du contenu inline
resource "openstack_objectstorage_object_v1" "bonjour" {
  container_name = openstack_objectstorage_container_v1.bucket.name
  name           = "bonjour.txt"
  content_type   = "text/plain"
  content        = "Bonjour depuis Terraform ! Objet stocke dans Swift.\n"
}

# Objet créé depuis un fichier local
resource "openstack_objectstorage_object_v1" "fichier" {
  container_name = openstack_objectstorage_container_v1.bucket.name
  name           = "exemple/donnees.json"
  content_type   = "application/json"
  source         = "${path.module}/donnees.json"
}
