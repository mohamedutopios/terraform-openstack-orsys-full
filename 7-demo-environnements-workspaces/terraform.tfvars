# Valeurs COMMUNES : un seul tfvars, chargé quel que soit le workspace.

cloud_name            = "kolla-aio"
public_key_path       = "~/.ssh/id_rsa.pub"
image_name            = "cirros"
external_network_name = "public"
dns_nameservers       = ["8.8.8.8"]
