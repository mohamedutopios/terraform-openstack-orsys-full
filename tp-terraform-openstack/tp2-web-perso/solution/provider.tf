# Cloud admin requis (création de flavor). Entrée lue dans ./clouds.yaml
provider "openstack" {
  cloud = var.cloud_name
}
