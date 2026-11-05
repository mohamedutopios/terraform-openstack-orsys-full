terraform {
    backend "s3" {
        bucket = "mohamed-formation"
        key = "openstack/mohamed/terraform.tfstate"
        region = "eu-west-3"
    }
}