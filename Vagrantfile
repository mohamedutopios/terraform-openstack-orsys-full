# -*- mode: ruby -*-
# OpenStack AIO (Kolla-Ansible 2024.1) sur VirtualBox
#
# Réseaux :
#   NIC1 (NAT)              : accès Internet de la VM (apt, pip, images Docker)
#   NIC2 (host-only)        : 192.168.56.10  -> réseau management/API OpenStack
#                             VIP Kolla : 192.168.56.250 (Terraform/Horizon depuis l'hôte)
#   NIC3 (host-only, no IP) : réseau externe Neutron (flat) -> floating IPs
#                             192.168.57.0/24 ; l'hôte y est présent en 192.168.57.1
#
# Disques additionnels :
#   /dev/sdb (40 Go) : LVM cinder-volumes (Cinder)
#   /dev/sdc (20 Go) : partition KOLLA_SWIFT_DATA (Swift)

DISK_DIR    = File.expand_path("disks", __dir__)
CINDER_DISK = File.join(DISK_DIR, "cinder.vdi")
SWIFT_DISK  = File.join(DISK_DIR, "swift.vdi")

Vagrant.configure("2") do |config|
  config.vm.box      = "bento/ubuntu-22.04"
  config.vm.hostname = "openstack-aio"

  # NIC2 : management / API
  config.vm.network "private_network", ip: "192.168.56.10"
  # NIC3 : réseau externe Neutron (aucune IP côté guest, Neutron gère)
  config.vm.network "private_network", ip: "192.168.57.10", auto_config: false

  config.vm.synced_folder ".", "/vagrant"

  config.vm.provider "virtualbox" do |vb|
    vb.name   = "openstack-aio-kolla"
    vb.cpus   = 8
    vb.memory = 16384
    vb.customize ["modifyvm", :id, "--nested-hw-virt", "on"]
    # Indispensable : trafic des floating IPs sur NIC3
    vb.customize ["modifyvm", :id, "--nicpromisc3", "allow-all"]

    FileUtils.mkdir_p(DISK_DIR)
    unless File.exist?(CINDER_DISK)
      vb.customize ["createmedium", "disk", "--filename", CINDER_DISK, "--size", 40960]
    end
    unless File.exist?(SWIFT_DISK)
      vb.customize ["createmedium", "disk", "--filename", SWIFT_DISK, "--size", 20480]
    end
    vb.customize ["storageattach", :id, "--storagectl", "SATA Controller",
                  "--port", 2, "--device", 0, "--type", "hdd", "--medium", CINDER_DISK]
    vb.customize ["storageattach", :id, "--storagectl", "SATA Controller",
                  "--port", 3, "--device", 0, "--type", "hdd", "--medium", SWIFT_DISK]
  end

  config.vm.provision "shell", path: "scripts/01-bootstrap.sh"
  config.vm.provision "shell", path: "scripts/02-deploy-kolla.sh"
  config.vm.provision "shell", path: "scripts/03-init-lab.sh"
end
