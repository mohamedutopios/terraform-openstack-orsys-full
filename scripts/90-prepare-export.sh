#!/usr/bin/env bash
# 90 - À lancer DANS la VM (vagrant ssh puis sudo -i) AVANT l'export OVA.
# Rend la VM utilisable par des tiers sans le contexte Vagrant d'origine.
set -euo pipefail

echo "=== [90] Accès générique : vagrant / vagrant (console + SSH) ==="
echo 'vagrant:vagrant' | chpasswd
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
systemctl restart ssh 2>/dev/null || systemctl restart sshd

# Clé publique "insecure" Vagrant (permet aussi un repackage en box Vagrant)
mkdir -p /home/vagrant/.ssh
curl -fsSL https://raw.githubusercontent.com/hashicorp/vagrant/main/keys/vagrant.pub \
  >> /home/vagrant/.ssh/authorized_keys || true
sort -u /home/vagrant/.ssh/authorized_keys -o /home/vagrant/.ssh/authorized_keys
chown -R vagrant:vagrant /home/vagrant/.ssh
chmod 700 /home/vagrant/.ssh && chmod 600 /home/vagrant/.ssh/authorized_keys

echo "=== [90] clouds.yaml embarqué dans la VM ==="
# Regénéré depuis passwords.yml : l'OVA reste autonome même sans le dossier terraform/
VIP="192.168.56.250"
ADMIN_PASS=$(awk '/^keystone_admin_password:/ {print $2}' /etc/kolla/passwords.yml)
cat > /home/vagrant/clouds.yaml <<EOF
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
chown vagrant:vagrant /home/vagrant/clouds.yaml

echo "=== [90] Nettoyage (réduit la taille de l'OVA) ==="
apt-get clean
journalctl --vacuum-time=1d || true
rm -rf /tmp/* /var/tmp/* || true

# Optionnel : remplissage à zéro de l'espace libre pour une OVA nettement plus
# compacte (long, et gonfle temporairement le VDI côté hôte) :
# dd if=/dev/zero of=/zerofill bs=1M || true; rm -f /zerofill; sync

echo "=== [90] Prêt pour l'export. Sur l'hôte : vagrant halt puis VBoxManage export ==="
