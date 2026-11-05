# Valeurs des variables pour ce déploiement

cloud_name      = "kolla-aio"
vm_count        = 2
public_key_path = "~/.ssh/id_rsa.pub"
image_name      = "cirros"
flavor_name     = "m1.tiny"
network_name    = "private"
subnet_name     = "private-subnet"
secgroup_name   = "allow-ssh-icmp"
