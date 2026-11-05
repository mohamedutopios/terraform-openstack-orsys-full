cloud_name            = "kolla-aio"
public_key_path       = "~/.ssh/id_rsa.pub"
external_network_name = "public"
subnet_cidr           = "10.10.2.0/24"
dns_nameservers       = ["8.8.8.8"]

image_url = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"

flavor_vcpus   = 2
flavor_ram_mb  = 2048
flavor_disk_gb = 10

volume_size_gb = 1

student_name    = "Mohamed"
welcome_message = "Bienvenue sur mon serveur web deploye par Terraform !"
