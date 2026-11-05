# Configuration du provider OpenStack.
# L'entrée "kolla-aio" est lue dans ./clouds.yaml (généré par le provisioning).
provider "openstack" {
  cloud = var.cloud_name
}


# provider "openstack" {
#   auth_url            = "http://192.168.56.250:5000/v3"  # auth_url (+ /v3 = identity_api_version: 3)
#   user_name           = "admin"                          # username
#   password            = var.openstack_password           # password -> JAMAIS en dur, cf. plus bas
#   tenant_name         = "admin"                          # project_name (nom historique "tenant")
#   user_domain_name    = "Default"
#   project_domain_name = "Default"
#   region              = "RegionOne"                      # region_name
#   endpoint_type       = "public"                         # interface
# }