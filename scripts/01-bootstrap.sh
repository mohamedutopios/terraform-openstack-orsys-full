#!/usr/bin/env bash
# 01 - Préparation OS : paquets, interfaces, disques Cinder/Swift
set -euo pipefail

MGMT_IP="192.168.56.10"

echo "=== [01] Détection des interfaces ==="
MGMT_IF=$(ip -o -4 addr show | awk -v ip="$MGMT_IP" '$4 ~ ip"/" {print $2}')
# Interface externe = interface physique sans IPv4 (NIC3)
EXT_IF=""
for i in $(ip -o link show | awk -F': ' '{print $2}' | cut -d'@' -f1); do
  case "$i" in lo|docker*|ovs*|br*|veth*) continue ;; esac
  if ! ip -4 addr show "$i" | grep -q 'inet '; then EXT_IF="$i"; break; fi
done

[ -n "$MGMT_IF" ] || { echo "ERREUR : interface management ($MGMT_IP) introuvable"; exit 1; }
[ -n "$EXT_IF" ]  || { echo "ERREUR : interface externe introuvable"; exit 1; }

echo "Management : $MGMT_IF ($MGMT_IP) | Externe : $EXT_IF"
cat > /etc/openstack-lab.env <<EOF
MGMT_IF=$MGMT_IF
EXT_IF=$EXT_IF
MGMT_IP=$MGMT_IP
VIP=192.168.56.250
EOF

echo "=== [01] Interface externe up (persistant) ==="
ip link set dev "$EXT_IF" up
cat > /etc/systemd/system/ext-if-up.service <<EOF
[Unit]
Description=Monte l'interface externe Neutron
After=network.target
[Service]
Type=oneshot
ExecStart=/usr/sbin/ip link set dev $EXT_IF up
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable ext-if-up.service

echo "=== [01] /etc/hosts ==="
# Vagrant mappe le hostname sur 127.0.2.1 : RabbitMQ exige que le hostname
# résolve uniquement vers l'IP de management -> on retire la ligne loopback.
sed -i '/^127\.0\.[12]\.1[[:space:]].*openstack-aio/d' /etc/hosts
grep -q "^$MGMT_IP openstack-aio" /etc/hosts || echo "$MGMT_IP openstack-aio" >> /etc/hosts

echo "=== [01] Désactivation IPv6 (NAT VirtualBox sans IPv6 fonctionnel) ==="
cat > /etc/sysctl.d/99-disable-ipv6.conf <<EOF
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
EOF
sysctl --system >/dev/null

echo "=== [01] Paquets système ==="
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y python3-dev python3-venv python3-pip libffi-dev gcc libssl-dev \
                   pkg-config libdbus-1-dev libglib2.0-dev \
                   lvm2 parted xfsprogs chrony

echo "=== [01] Disque Cinder (/dev/sdb -> VG cinder-volumes) ==="
if ! vgs cinder-volumes >/dev/null 2>&1; then
  pvcreate /dev/sdb
  vgcreate cinder-volumes /dev/sdb
fi

echo "=== [01] Disque Swift (/dev/sdc -> partition KOLLA_SWIFT_DATA, label d0) ==="
if ! blkid /dev/sdc1 >/dev/null 2>&1; then
  parted /dev/sdc -s -- mklabel gpt mkpart KOLLA_SWIFT_DATA 1 -1
  sleep 2
  mkfs.xfs -f -L d0 /dev/sdc1
fi

echo "=== [01] Terminé ==="
