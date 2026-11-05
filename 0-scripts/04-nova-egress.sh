#!/usr/bin/env bash
# 04-nova-egress.sh — v2.0
# Kolla-Ansible AIO, VirtualBox: sortie Internet via br-ex et NIC NAT.
# Exécuter en root sur l'hôte Ubuntu (provisioner Vagrant).
set -Eeuo pipefail
trap 'echo "[ERREUR] Ligne $LINENO : $BASH_COMMAND" >&2' ERR

EXT_GW_IP="192.168.57.254"
EXT_CIDR="192.168.57.0/24"
EXT_BRIDGE="br-ex"
PRIVATE_CIDR="10.0.0.0/24"
DNS1="1.1.1.1"
DNS2="8.8.8.8"
SECGROUP="web-ssh-icmp"

log() { printf '\n==> %s\n' "$*"; }
fail() { echo "[ERREUR] $*" >&2; exit 1; }
need() { command -v "$1" >/dev/null || fail "Commande absente : $1"; }
[ "$(id -u)" -eq 0 ] || fail "Exécuter ce script en root (sudo)."
for cmd in ip iptables systemctl sysctl awk grep docker; do need "$cmd"; done
[ -f /opt/kolla/bin/activate ] || fail "Environnement Python Kolla absent"
[ -f /etc/kolla/admin-openrc.sh ] || fail "Fichier admin-openrc.sh absent"

log '[1/6] Installation de la passerelle Internet'
cat > /usr/local/sbin/nova-egress.sh <<'GATEWAY'
#!/usr/bin/env bash
set -Eeuo pipefail
EXT_GW_CIDR="192.168.57.254/24"
EXT_NET="192.168.57.0/24"
for ((i=1;i<=120;i++)); do
  ip link show br-ex >/dev/null 2>&1 && break
  sleep 5
done
ip link show br-ex >/dev/null 2>&1 || { echo 'br-ex introuvable' >&2; exit 1; }
WAN="$(ip -4 route show default | awk '$1=="default" {print $5; exit}')"
[ -n "$WAN" ] || { echo 'Aucune interface de sortie par défaut' >&2; exit 1; }
[ "$WAN" != 'br-ex' ] || { echo 'La route par défaut pointe vers br-ex : refus' >&2; exit 1; }
ip link set br-ex up
# "replace" n'est pas fiable pour une adresse existante sur toutes les versions d'iproute2.
if ! ip -4 -o addr show dev br-ex | grep -q 'inet 192\.168\.57\.254/24 '; then
  ip -4 addr show dev br-ex | grep -q 'inet 192\.168\.57\.254/' && ip -4 addr flush dev br-ex to 192.168.57.254/32 || true
  ip addr add "$EXT_GW_CIDR" dev br-ex
fi
sysctl -q -w net.ipv4.ip_forward=1
iptables -w -t nat -C POSTROUTING -s "$EXT_NET" -o "$WAN" -j MASQUERADE 2>/dev/null || iptables -w -t nat -A POSTROUTING -s "$EXT_NET" -o "$WAN" -j MASQUERADE
iptables -w -C FORWARD -s "$EXT_NET" -o "$WAN" -j ACCEPT 2>/dev/null || iptables -w -I FORWARD 1 -s "$EXT_NET" -o "$WAN" -j ACCEPT
iptables -w -C FORWARD -d "$EXT_NET" -i "$WAN" -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT 2>/dev/null || iptables -w -I FORWARD 1 -d "$EXT_NET" -i "$WAN" -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
printf 'Passerelle OK : br-ex=%s, WAN=%s\n' "$EXT_GW_CIDR" "$WAN"
GATEWAY
chmod 755 /usr/local/sbin/nova-egress.sh

log '[2/6] Persistance systemd et sysctl'
printf 'net.ipv4.ip_forward = 1\n' > /etc/sysctl.d/99-nova-egress.conf
cat > /etc/systemd/system/nova-egress.service <<'UNIT'
[Unit]
Description=Passerelle Internet pour le réseau externe Neutron
Wants=network-online.target
After=network-online.target docker.service
[Service]
Type=oneshot
ExecStart=/usr/local/sbin/nova-egress.sh
RemainAfterExit=yes
TimeoutStartSec=900
[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload
systemctl enable nova-egress.service >/dev/null
systemctl restart nova-egress.service

log '[3/6] Identification explicite des ressources OpenStack'
# Les fichiers Kolla/OpenRC peuvent contenir des variables non définies.
set +u
# shellcheck disable=SC1091
source /opt/kolla/bin/activate
# shellcheck disable=SC1091
source /etc/kolla/admin-openrc.sh
set -u
need openstack

# Identifier le subnet externe par son CIDR et vérifier que son réseau est externe.
EXT_SUBNET=''; EXT_NET=''
while read -r sid; do
  cidr="$(openstack subnet show "$sid" -f value -c cidr)"
  [ "$cidr" = "$EXT_CIDR" ] || continue
  [ -z "$EXT_SUBNET" ] || fail "Plusieurs subnets correspondent à $EXT_CIDR"
  EXT_SUBNET="$sid"
done < <(openstack subnet list -f value -c ID)
[ -n "$EXT_SUBNET" ] || fail "Aucun subnet $EXT_CIDR trouvé"
EXT_NET="$(openstack subnet show "$EXT_SUBNET" -f value -c network_id)"
[ "$(openstack network show "$EXT_NET" -f value -c router:external)" = 'True' ] || fail "Le réseau $EXT_NET n'est pas externe"

PRIV_SUBNET=''
while read -r sid; do
  cidr="$(openstack subnet show "$sid" -f value -c cidr)"
  [ "$cidr" = "$PRIVATE_CIDR" ] || continue
  [ -z "$PRIV_SUBNET" ] || fail "Plusieurs subnets correspondent à $PRIVATE_CIDR"
  PRIV_SUBNET="$sid"
done < <(openstack subnet list -f value -c ID)
[ -n "$PRIV_SUBNET" ] || fail "Subnet privé $PRIVATE_CIDR introuvable"
PRIV_NET="$(openstack subnet show "$PRIV_SUBNET" -f value -c network_id)"
printf 'Externe : %s (%s) / privé : %s (%s)\n' "$EXT_NET" "$EXT_SUBNET" "$PRIV_NET" "$PRIV_SUBNET"

log '[4/6] Passerelle externe et DNS privé'
CUR_GW="$(openstack subnet show "$EXT_SUBNET" -f value -c gateway_ip)"
if [ "$CUR_GW" != "$EXT_GW_IP" ]; then
  openstack subnet set --gateway "$EXT_GW_IP" "$EXT_SUBNET"
  echo 'Passerelle modifiée : attente de la synchronisation Neutron (sans redémarrer L3)'
fi
openstack subnet set --no-dns-nameservers --dns-nameserver "$DNS1" --dns-nameserver "$DNS2" "$PRIV_SUBNET"

log '[5/6] Groupe de sécurité et règles manquantes'
if ! openstack security group show "$SECGROUP" >/dev/null 2>&1; then
  openstack security group create "$SECGROUP" --description 'SSH, HTTP, ICMP entrants' >/dev/null
fi
SG_ID="$(openstack security group show "$SECGROUP" -f value -c id)"
# Une règle identique peut déjà exister ; interroger l'API pour éviter les doublons.
ensure_rule() {
  local protocol="$1" port="$2" match=0
  local rid direction ethertype proto minport maxport remote
  while read -r rid; do
    [ -n "$rid" ] || continue
    direction="$(openstack security group rule show "$rid" -f value -c direction)"
    ethertype="$(openstack security group rule show "$rid" -f value -c ether_type)"
    proto="$(openstack security group rule show "$rid" -f value -c protocol)"
    minport="$(openstack security group rule show "$rid" -f value -c port_range_min)"
    maxport="$(openstack security group rule show "$rid" -f value -c port_range_max)"
    remote="$(openstack security group rule show "$rid" -f value -c remote_ip_prefix)"
    if [ "$direction" = ingress ] && [ "$ethertype" = IPv4 ] && [ "$proto" = "$protocol" ] && { [ "$remote" = '0.0.0.0/0' ] || [ "$remote" = None ]; }; then
      if [ "$protocol" = icmp ] || { [ "$minport" = "$port" ] && [ "$maxport" = "$port" ]; }; then match=1; break; fi
    fi
  done < <(openstack security group rule list "$SG_ID" -f value -c ID)
  if [ "$match" -eq 0 ]; then
    if [ "$protocol" = icmp ]; then
      openstack security group rule create --ingress --ethertype IPv4 --protocol icmp "$SG_ID" >/dev/null
    else
      openstack security group rule create --ingress --ethertype IPv4 --protocol tcp --dst-port "$port" "$SG_ID" >/dev/null
    fi
    echo "Règle ajoutée : $protocol ${port:-all}"
  else
    echo "Règle déjà présente : $protocol ${port:-all}"
  fi
}
ensure_rule icmp ''
ensure_rule tcp 22
ensure_rule tcp 80

log '[6/6] Vérification du namespace et du routage du routeur Neutron'
# Sélectionner un routeur réellement relié au réseau externe, pas le premier au hasard.
ROUTER_ID=''
while read -r rid; do
  [ -n "$rid" ] || continue
  gw_info="$(openstack router show "$rid" -f value -c external_gateway_info)"
  case "$gw_info" in
    *"$EXT_NET"*)
      [ -z "$ROUTER_ID" ] || fail "Plusieurs routeurs utilisent ce réseau externe ; préciser le routeur"
      ROUTER_ID="$rid" ;;
  esac
done < <(openstack router list -f value -c ID)
[ -n "$ROUTER_ID" ] || fail "Aucun routeur connecté au réseau externe $EXT_NET"
ROUTER_NS="qrouter-$ROUTER_ID"
echo "Routeur : $ROUTER_ID ; namespace : $ROUTER_NS"
ready=0
for ((i=1;i<=24;i++)); do
  if ip netns list | grep -Fq "$ROUTER_NS" && ip netns exec "$ROUTER_NS" ip -4 route 2>/dev/null | grep -Fq "default via $EXT_GW_IP "; then
    ready=1; break
  fi
  sleep 5
done
[ "$ready" -eq 1 ] || fail "Route par défaut via $EXT_GW_IP absente dans $ROUTER_NS (ou namespace inaccessible)"
ip netns exec "$ROUTER_NS" ip -4 route
if ip netns exec "$ROUTER_NS" ping -c 3 -W 2 8.8.8.8; then
  echo '[OK] Ping Internet depuis le routeur Neutron.'
else
  echo '[ATTENTION] Ping du namespace échoué. Tester une VM Nova avant de conclure à une panne.' >&2
fi
printf '\n[OK] Passerelle configurée, routeur prêt. Vérifier SSH et Internet depuis une instance Nova.\n'
