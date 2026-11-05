# Configuration du provider OpenStack (entrée lue dans ./clouds.yaml)
provider "openstack" {
  cloud = var.cloud_name
}
