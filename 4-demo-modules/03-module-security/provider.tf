# Le provider est configuré UNE fois dans le root ; les modules l'héritent.
provider "openstack" {
  cloud = var.cloud_name
}
