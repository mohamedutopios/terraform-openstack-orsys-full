# Environnement PROD — SSH restreint au réseau externe
# Le gabarit visé est m1.small, mais m1.small (10 Go de disque) ne tient pas
# sur le lab quand testo tourne (hyperviseur limité à 30 Go) : m1.tiny pour la démo.

environment           = "prod"
cloud_name            = "kolla-aio"
public_key_path       = "~/.ssh/id_rsa.pub"
image_name            = "cirros"
flavor_name           = "m1.tiny"
external_network_name = "public"
subnet_cidr           = "10.50.3.0/24"
dns_nameservers       = ["8.8.8.8"]
ssh_allowed_cidr      = "192.168.57.0/24"
