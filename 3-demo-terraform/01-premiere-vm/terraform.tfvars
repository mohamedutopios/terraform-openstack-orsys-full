# Valeurs des variables pour ce déploiement.
# Modifiez ici sans toucher au code (variables.tf contient les défauts).

cloud_name      = "kolla-aio"
public_key_path = "~/.ssh/id_rsa.pub"
image_name      = "cirros"
flavor_name     = "m1.tiny"
network_name    = "private"
subnet_name     = "private-subnet"
secgroup_name   = "allow-ssh-icmp"
floating_pool   = "public"
