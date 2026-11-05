# Obligatoire dans chaque module : le provider openstack n'est pas dans le
# namespace hashicorp, sans cette déclaration Terraform chercherait
# "hashicorp/openstack" (inexistant).
terraform {
  required_providers {
    openstack = {
      source = "terraform-provider-openstack/openstack"
    }
  }
}
