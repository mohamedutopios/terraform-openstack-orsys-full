cloud_name            = "kolla-aio"
public_key_path       = "~/.ssh/id_rsa.pub"
external_network_name = "public"

public_subnet_cidr  = "10.30.1.0/24"
private_subnet_cidr = "10.30.2.0/24"
dns_nameservers     = ["8.8.8.8"]

image_url_bionic = "https://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-amd64.img"
image_url_jammy  = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"

flavor_vcpus  = 2
flavor_ram_mb = 2048
# 20 Go sur le schéma d'origine, ramené à 10 Go : l'hyperviseur du lab n'a
# que 30 Go pour l'ensemble des instances.
flavor_disk_gb = 10
