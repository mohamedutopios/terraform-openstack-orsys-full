# L'entrée est lue dans ./clouds.yaml
provider "openstack" {
  cloud = var.cloud_name
}
