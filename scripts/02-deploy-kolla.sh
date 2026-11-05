#!/usr/bin/env bash
# 02 - Installation Kolla-Ansible 2024.1, anneaux Swift, déploiement AIO
set -euo pipefail
source /etc/openstack-lab.env

RELEASE="2024.1"
VENV="/opt/kolla"
INV="/etc/kolla/all-in-one"
SWIFT_IMAGE="quay.io/openstack.kolla/swift-base:${RELEASE}-ubuntu-jammy"

echo "=== [02] Virtualenv + kolla-ansible ${RELEASE} ==="
if [ ! -d "$VENV" ]; then
  python3 -m venv "$VENV"
fi
source "$VENV/bin/activate"
pip install -U pip
pip install 'kolla-ansible~=18.0' 'ansible-core>=2.15,<2.17'

echo "=== [02] Configuration /etc/kolla ==="
mkdir -p /etc/kolla
cp -rn "$VENV/share/kolla-ansible/etc_examples/kolla/"* /etc/kolla/ || true
cp -n  "$VENV/share/kolla-ansible/ansible/inventory/all-in-one" "$INV" || true
# La branche stable/2024.1 a été renommée unmaintained/2024.1 (fin de maintenance
# OpenStack Caracal) ; on corrige les dépendances Galaxy avant install-deps.
sed -i 's|stable/2024\.1|unmaintained/2024.1|g' "$VENV/share/kolla-ansible/requirements.yml"
kolla-ansible install-deps

if ! grep -q 'keystone_admin_password: [a-zA-Z0-9]' /etc/kolla/passwords.yml; then
  kolla-genpwd
fi

echo "=== [02] globals.yml ==="
cat > /etc/kolla/globals.yml <<EOF
---
workaround_ansible_issue_8743: yes
kolla_base_distro: "ubuntu"
openstack_release: "${RELEASE}"

kolla_internal_vip_address: "${VIP}"
network_interface: "${MGMT_IF}"
neutron_external_interface: "${EXT_IF}"
neutron_plugin_agent: "openvswitch"
enable_neutron_provider_networks: "yes"

# VirtualBox : pas de KVM fiable -> émulation QEMU
nova_compute_virt_type: "qemu"

# Cinder (backend LVM sur /dev/sdb)
enable_cinder: "yes"
enable_cinder_backend_lvm: "yes"

# Swift (partition KOLLA_SWIFT_DATA sur /dev/sdc)
enable_swift: "yes"
swift_devices_match_mode: "strict"
swift_devices_name: "KOLLA_SWIFT_DATA"

enable_horizon: "yes"
EOF

echo "=== [02] bootstrap-servers (installe Docker) ==="
kolla-ansible -i "$INV" bootstrap-servers

echo "=== [02] SDK Docker pour le Python système ==="
# Les modules Ansible (prechecks/deploy) tournent sous /usr/bin/python3, pas le
# venv : le SDK docker et dbus-python doivent être présents côté système.
/usr/bin/python3 -m pip install 'docker>=6.0.0,<7.0.0' 'requests<2.32' dbus-python

echo "=== [02] Anneaux Swift ==="
SWIFT_CFG=/etc/kolla/config/swift
mkdir -p "$SWIFT_CFG"
if [ ! -f "$SWIFT_CFG/object.ring.gz" ]; then
  docker pull "$SWIFT_IMAGE"
  # 3 anneaux : object(6000) / account(6001) / container(6002), 1 réplique, 1 device (d0)
  for ring in object:6000 account:6001 container:6002; do
    name="${ring%%:*}"; port="${ring##*:}"
    docker run --rm -v "$SWIFT_CFG":"$SWIFT_CFG" "$SWIFT_IMAGE" \
      swift-ring-builder "$SWIFT_CFG/${name}.builder" create 10 1 1
    docker run --rm -v "$SWIFT_CFG":"$SWIFT_CFG" "$SWIFT_IMAGE" \
      swift-ring-builder "$SWIFT_CFG/${name}.builder" add "r1z1-${MGMT_IP}:${port}/d0" 1
    docker run --rm -v "$SWIFT_CFG":"$SWIFT_CFG" "$SWIFT_IMAGE" \
      swift-ring-builder "$SWIFT_CFG/${name}.builder" rebalance
  done
fi

echo "=== [02] prechecks + deploy (long : 30-45 min) ==="
kolla-ansible -i "$INV" prechecks
kolla-ansible -i "$INV" deploy
kolla-ansible -i "$INV" post-deploy

echo "=== [02] Client OpenStack ==="
pip install python-openstackclient

echo "=== [02] clouds.yaml pour l'hôte (Terraform) ==="
ADMIN_PASS=$(awk '/^keystone_admin_password:/ {print $2}' /etc/kolla/passwords.yml)
mkdir -p /vagrant/terraform
cat > /vagrant/terraform/clouds.yaml <<EOF
clouds:
  kolla-aio:
    auth:
      auth_url: http://${VIP}:5000
      username: admin
      password: ${ADMIN_PASS}
      project_name: admin
      user_domain_name: Default
      project_domain_name: Default
    region_name: RegionOne
    interface: public
    identity_api_version: 3
EOF

echo "=== [02] Déploiement terminé. Horizon : http://${VIP} (admin / ${ADMIN_PASS}) ==="
