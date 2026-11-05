# Environnement DEV — tout ouvert, petit gabarit

environment           = "dev"
cloud_name            = "kolla-aio"
public_key_path       = "~/.ssh/id_rsa.pub"
image_name            = "cirros"
flavor_name           = "m1.tiny"
external_network_name = "public"
subnet_cidr           = "10.50.1.0/24"
dns_nameservers       = ["8.8.8.8"]
ssh_allowed_cidr      = "0.0.0.0/0"
