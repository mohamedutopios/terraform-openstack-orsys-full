# OpenStack AIO (OVA) — VMs Nova joignables (SSH, HTTP) ET connectées à Internet

Version 1.2 — VirtualBox 7.x sur poste Windows x86_64
(OVA construite par le Vagrantfile `bento/ubuntu-22.04` : NIC3 host-only `192.168.57.0/24`, promiscuité `allow-all`)
VM `openstack-aio-kolla` : Ubuntu 22.04 + OpenStack 2024.1 (Kolla-Ansible)

**Résultat attendu à la fin :**

| Depuis | Vers | Résultat |
|---|---|---|
| Votre poste | Floating IP d'une VM Nova (`192.168.57.1xx`) | `ping`, `ssh`, `http` en **direct**, sans redirection de ports |
| VM Nova | Internet | `ping 8.8.8.8`, `apt-get update`, `apt-get install` OK |
| Votre poste | Horizon / APIs (`192.168.56.250`) | OK (Horizon, CLI, Terraform) |

---

## 0. Principe — à lire avant de commencer

```
                       ┌─────────────────────── VM openstack-aio-kolla ───────────────────────┐
                       │                                                                       │
 Internet ◄── NAT VBox ─┤ Carte 1 (NAT,    10.0.2.15) ◄── MASQUERADE ◄──┐                     │
                       │                                                │                     │
 VOTRE POSTE           │                                         br-ex : 192.168.57.254       │
  192.168.56.1 ── host-only n°1 ── Carte 2 (192.168.56.10 + VIP .250)   ▲  (passerelle des    │
                       │                                                │   floating IPs)     │
  192.168.57.1 ── host-only n°2 ── Carte 3 (pas d'IP, branchée dans br-ex)                    │
                       │                    │                                                 │
                       │                    └── Routeur Neutron (qg-…) ── floating IPs .100-.200
                       │                                                     └── VMs Nova    │
                       └───────────────────────────────────────────────────────────────────────┘
```

Deux flux, deux chemins :

1. **Poste → VM Nova** : votre poste possède `192.168.57.1` sur le réseau host-only n°2. Les floating IPs sont sur ce même réseau, donc l'accès est direct pour tous les ports et tous les protocoles. Il faut que la carte 3 soit en **promiscuité « Autoriser tout »**.
2. **VM Nova → Internet** : par défaut, la passerelle du réseau externe Neutron est `192.168.57.1` (votre poste), qui ne route pas. Ce guide la remplace par `192.168.57.254`, une IP posée sur `br-ex` **dans la VM AIO**. La VM AIO fait ensuite le NAT (MASQUERADE) vers sa carte 1, qui a Internet.

Votre poste n'a rien à router : la solution fonctionne pareil sur tous les postes apprenants.

---

## 1. Prérequis

- VirtualBox **7.x** + Extension Pack de la même version.
- Poste : 8 threads CPU et 16 Go de RAM à dédier à la VM, environ 100 Go de disque libre.
- Fichier `openstack-aio-kolla.ova`, téléchargé au §1.1.

### 1.1 Télécharger l'OVA

Lien : **https://drive.google.com/file/d/1rUxHJUuos382GT93wGGhEvsvo8NGShUH/view?usp=drive_link**

1. Ouvrir le lien dans un navigateur, connecté à un compte Google (obligatoire pour les gros fichiers).
2. Cliquer sur **Télécharger** (icône flèche en haut à droite).
3. Drive affiche « Impossible d'analyser ce fichier pour détecter les virus » : cliquer sur **Télécharger quand même**. C'est normal pour un fichier de cette taille.
4. Enregistrer le fichier sur un disque qui a au moins 100 Go libres. Ne pas le décompresser : une OVA s'importe telle quelle.

### ✅ Contrôle n°0 (poste)

```powershell
Get-Item .\openstack-aio-kolla.ova | Select-Object Name, @{n='Taille (Go)';e={[math]::Round($_.Length/1GB,1)}}
```

Le fichier doit avoir l'extension `.ova` (pas `.ova.crdownload` ni `.part`) et une taille de plusieurs Go. Un fichier de quelques Ko est la page HTML d'avertissement de Drive et non l'OVA : recommencez le téléchargement depuis le navigateur.
- Windows : Hyper-V désactivé si VirtualBox affiche une erreur VT-x/AMD-V (voir §10).
- Client OpenSSH présent sur le poste (inclus dans Windows 10/11). Test : `ssh -V` dans PowerShell.

Toutes les commandes « **poste** » se lancent dans **PowerShell**. Les commandes « **AIO** » se lancent dans la VM, en root.

---

## 2. Créer les deux réseaux host-only (AVANT d'importer)

Les réseaux host-only ne sont jamais transportés dans une OVA : il faut les créer sur chaque poste.

**Fichier → Outils → Gestionnaire de réseau → onglet « Réseaux hôte uniquement »**

### 2.1 Réseau n°1 — management

1. **Créer**.
2. Onglet **Adaptateur** : cocher *Configurer l'adaptateur manuellement*
   - Adresse IPv4 : `192.168.56.1`
   - Masque : `255.255.255.0`
3. Onglet **Serveur DHCP** : **décocher** *Activer le serveur*.
4. **Appliquer**.

### 2.2 Réseau n°2 — externe (floating IPs)

1. **Créer** une deuxième fois.
2. Onglet **Adaptateur** : cocher *Configurer l'adaptateur manuellement*
   - Adresse IPv4 : `192.168.57.1`
   - Masque : `255.255.255.0`
3. Onglet **Serveur DHCP** : **décocher** *Activer le serveur*.
4. **Appliquer**.

### ✅ Contrôle n°1 (poste)

```powershell
ipconfig | Select-String -Context 0,4 "VirtualBox Host-Only"
```

Attendu : une carte en `192.168.56.1` et une carte en `192.168.57.1`. Notez le **nom** exact de chaque adaptateur dans la colonne *Nom* du Gestionnaire de réseau (par exemple `VirtualBox Host-Only Ethernet Adapter` et `VirtualBox Host-Only Ethernet Adapter #2`).

---

## 3. Importer l'OVA (sans démarrer)

1. **Fichier → Importer un appareil virtuel…** → sélectionner `openstack-aio-kolla.ova`.
2. Vérifier : **8 CPU**, **16384 Mo** de RAM (jamais moins de 12288).
3. **Politique d'adresse MAC** : *Générer de nouvelles adresses MAC pour toutes les cartes réseau*.
4. **Terminer**. Ne démarrez pas encore la VM.

---

## 4. Câbler les 3 cartes de la VM

VM éteinte → **Configuration → Réseau**. **Ne changez pas l'ordre des cartes.**

| Carte | Mode d'accès | Nom | Avancé → Mode Promiscuité |
|---|---|---|---|
| Carte 1 | NAT | — | (inchangé) |
| Carte 2 | Réseau privé hôte | adaptateur `192.168.56.1` | Refuser |
| Carte 3 | Réseau privé hôte | adaptateur `192.168.57.1` | **Autoriser tout** |

Sans **Autoriser tout** sur la carte 3, VirtualBox ne livre à la carte que les frames destinées à sa propre MAC. Les floating IPs portent la MAC du port routeur Neutron, donc rien ne passe : ni l'accès poste → VM, ni l'accès VM → Internet.

Équivalent en ligne de commande (poste, VM éteinte, adaptez les noms d'adaptateurs) :

```powershell
$VBM = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
& $VBM modifyvm "openstack-aio-kolla" `
  --nic1 nat `
  --nic2 hostonly --hostonlyadapter2 "VirtualBox Host-Only Ethernet Adapter" `
  --nic3 hostonly --hostonlyadapter3 "VirtualBox Host-Only Ethernet Adapter #2" `
  --nicpromisc3 allow-all
```

### ✅ Contrôle n°2 (poste)

```powershell
$VBM = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
& $VBM showvminfo "openstack-aio-kolla" --machinereadable | Select-String '^(nic[1-3]|hostonlyadapter[23]|nicpromisc3)='
```

Attendu :

```
nic1="nat"
nic2="hostonly"
hostonlyadapter2="VirtualBox Host-Only Ethernet Adapter"
nic3="hostonly"
hostonlyadapter3="VirtualBox Host-Only Ethernet Adapter #2"
nicpromisc3="allow-all"
```

---

## 5. Démarrer et attendre OpenStack

1. Clic droit sur la VM → **Démarrer → Démarrage sans affichage**.
2. Attendre **5 à 10 minutes**, le temps que les conteneurs Kolla se stabilisent.

### ✅ Contrôle n°3 (poste)

```powershell
ping 192.168.56.10      # VM AIO      → carte 2 OK
ping 192.168.56.250     # VIP OpenStack → keepalived OK
```

Ouvrez ensuite `http://192.168.56.250` : la page de connexion Horizon doit s'afficher.

---

## 6. Ouvrir une session root dans l'AIO avec le client OpenStack

Poste :

```powershell
ssh vagrant@192.168.56.10          # mot de passe : vagrant
```

AIO :

```bash
sudo -i
source /opt/kolla/bin/activate
source /etc/kolla/admin-openrc.sh
openstack service list             # les services doivent répondre
grep keystone_admin_password /etc/kolla/passwords.yml   # mot de passe admin Horizon
```

Toutes les commandes **AIO** des étapes 7 à 9 se lancent dans cette session root, avec l'environnement chargé.

---

## 7. Donner Internet aux VMs Nova (passerelle 192.168.57.254 dans l'AIO)

> **OVA reconstruite avec `scripts/04-nova-egress.sh` (§13)** : les étapes 7.1 à 7.4 et 8.1 sont déjà faites dans l'image. Faites uniquement les contrôles n°4 et n°5, puis passez au §8.2.

### 7.1 Installer le script de passerelle

Ce script attend que `br-ex` existe (créé par le conteneur Open vSwitch), lui donne l'IP `192.168.57.254`, active le routage et ajoute le NAT vers la carte qui porte la route par défaut (la carte 1).

AIO :

```bash
cat > /usr/local/sbin/nova-egress.sh <<'EOF'
#!/bin/bash
# Passerelle Internet pour le réseau externe Neutron (floating IPs)
set -euo pipefail

EXT_GW_CIDR="192.168.57.254/24"
EXT_NET="192.168.57.0/24"

# 1. Attendre br-ex (créé par le conteneur openvswitch_vswitchd)
for i in $(seq 1 120); do
  ip link show br-ex >/dev/null 2>&1 && break
  sleep 5
done
ip link show br-ex >/dev/null 2>&1 || { echo "br-ex introuvable" >&2; exit 1; }

# 2. Interface de sortie = celle de la route par défaut (carte 1 NAT)
WAN="$(ip -4 route show default | awk '{print $5; exit}')"
[ -n "$WAN" ] || { echo "aucune route par défaut" >&2; exit 1; }

# 3. IP de passerelle sur br-ex
ip link set br-ex up
ip addr replace "$EXT_GW_CIDR" dev br-ex

# 4. Routage
sysctl -q -w net.ipv4.ip_forward=1

# 5. NAT sortant + autorisations FORWARD (idempotent)
iptables -t nat -C POSTROUTING -s "$EXT_NET" -o "$WAN" -j MASQUERADE 2>/dev/null \
  || iptables -t nat -A POSTROUTING -s "$EXT_NET" -o "$WAN" -j MASQUERADE
iptables -C FORWARD -s "$EXT_NET" -o "$WAN" -j ACCEPT 2>/dev/null \
  || iptables -I FORWARD 1 -s "$EXT_NET" -o "$WAN" -j ACCEPT
iptables -C FORWARD -d "$EXT_NET" -i "$WAN" -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT 2>/dev/null \
  || iptables -I FORWARD 1 -d "$EXT_NET" -i "$WAN" -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

echo "nova-egress OK : br-ex=$EXT_GW_CIDR, sortie=$WAN"
EOF
chmod 755 /usr/local/sbin/nova-egress.sh
```

### 7.2 Le rendre persistant au redémarrage

AIO :

```bash
cat > /etc/sysctl.d/99-nova-egress.conf <<'EOF'
net.ipv4.ip_forward = 1
EOF

cat > /etc/systemd/system/nova-egress.service <<'EOF'
[Unit]
Description=Passerelle Internet pour les floating IPs Neutron (br-ex 192.168.57.254)
Wants=network-online.target
After=network-online.target docker.service

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/nova-egress.sh
RemainAfterExit=yes
TimeoutStartSec=900

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now nova-egress.service
systemctl status nova-egress.service --no-pager
```

### ✅ Contrôle n°4 (AIO)

```bash
ip -4 addr show br-ex                         # inet 192.168.57.254/24
iptables -t nat -S POSTROUTING | grep 192.168.57.0/24   # règle MASQUERADE présente
```

Poste :

```powershell
ping 192.168.57.254       # l'AIO répond sur le réseau externe → carte 3 + promiscuité OK
```

### 7.3 Faire pointer Neutron vers cette passerelle

AIO :

```bash
EXT_NET=$(openstack network list --external -f value -c Name | head -1)
EXT_SUBNET=$(openstack subnet list --network "$EXT_NET" -f value -c ID | head -1)
echo "Réseau externe : $EXT_NET  /  sous-réseau : $EXT_SUBNET"

openstack subnet show "$EXT_SUBNET" -c cidr -c gateway_ip -c allocation_pools
# gateway_ip actuel = 192.168.57.1 (votre poste, qui ne route pas)

openstack subnet set --gateway 192.168.57.254 "$EXT_SUBNET"
openstack subnet show "$EXT_SUBNET" -c gateway_ip      # 192.168.57.254
```

Pour que le routeur existant prenne en compte la nouvelle passerelle, redémarrez l'agent L3 :

```bash
docker restart neutron_l3_agent
sleep 30
```

### 7.4 Donner un DNS aux VMs Nova

AIO :

```bash
PRIV_NET=private
PRIV_SUBNET=$(openstack subnet list --network "$PRIV_NET" -f value -c ID | head -1)
openstack subnet set --no-dns-nameservers \
  --dns-nameserver 1.1.1.1 --dns-nameserver 8.8.8.8 "$PRIV_SUBNET"
openstack subnet show "$PRIV_SUBNET" -c dns_nameservers
```

Les VMs déjà démarrées ne prennent ce DNS qu'après un renouvellement DHCP ou un reboot.

### ✅ Contrôle n°5 — le routeur Neutron sort sur Internet (AIO)

```bash
ROUTER_ID=$(openstack router list -f value -c ID | head -1)
docker exec neutron_l3_agent ip netns exec qrouter-$ROUTER_ID ip -4 route
# attendu : default via 192.168.57.254 dev qg-...

docker exec neutron_l3_agent ip netns exec qrouter-$ROUTER_ID ping -c 3 8.8.8.8
# attendu : 3 réponses
```

Si ce ping échoue, n'allez pas plus loin : voir §10.

---

## 8. Préparer l'accès : security group et keypair

### 8.1 Security group SSH + HTTP + ICMP (AIO)

```bash
openstack security group create web-ssh-icmp --description "SSH, HTTP, ICMP entrants"
openstack security group rule create --ingress --protocol icmp web-ssh-icmp
openstack security group rule create --ingress --protocol tcp --dst-port 22 web-ssh-icmp
openstack security group rule create --ingress --protocol tcp --dst-port 80 web-ssh-icmp
openstack security group rule list web-ssh-icmp
```

Le trafic sortant (egress) est autorisé par défaut : rien à ajouter pour Internet.
Les security groups sont **propres à chaque projet** : refaites cette étape si vous travaillez dans un autre projet que `admin`.

### 8.2 Keypair (la clé est générée sur le poste)

Poste :

```powershell
ssh-keygen -t ed25519 -f $HOME\.ssh\lab_nova -N '""'
scp $HOME\.ssh\lab_nova.pub vagrant@192.168.56.10:
```

AIO :

```bash
openstack keypair create --public-key /home/vagrant/lab_nova.pub lab-key
openstack keypair list
```

---

## 9. Valider avec une VM CirrOS (rapide, ~1 min de boot)

### 9.1 Créer la VM et sa floating IP (AIO)

```bash
openstack image list          # repérer le nom de l'image CirrOS (ex. cirros)

openstack server create \
  --image cirros --flavor m1.tiny --network private \
  --security-group web-ssh-icmp --key-name lab-key \
  --wait cirros-test

FIP=$(openstack floating ip create "$EXT_NET" -f value -c floating_ip_address)
openstack server add floating ip cirros-test "$FIP"
echo "Floating IP : $FIP"
```

### ✅ Contrôle n°6 — accès direct depuis le poste

Poste (remplacez `192.168.57.1xx` par la floating IP affichée) :

```powershell
ping 192.168.57.1xx
ssh -i $HOME\.ssh\lab_nova cirros@192.168.57.1xx
```

### ✅ Contrôle n°7 — Internet depuis la VM (dans la session SSH CirrOS)

```sh
ping -c 3 8.8.8.8                 # sortie IP OK
nslookup example.com              # DNS OK
curl -sI http://example.com | head -1   # HTTP sortant OK
```

### ✅ Contrôle n°8 — HTTP entrant (dans la session SSH CirrOS)

```sh
sudo sh -c 'while true; do printf "HTTP/1.0 200 OK\r\n\r\nOK depuis Nova\n" | nc -l -p 80; done' &
```

Poste :

```powershell
curl.exe http://192.168.57.1xx    # → OK depuis Nova
```

---

## 10. Valider la mise à jour d'une vraie distribution (Ubuntu + nginx)

Ce test prouve qu'une VM peut faire `apt-get update`, puis installer et exposer un service. Les instances tournent en **émulation QEMU** (pas de KVM imbriqué) : comptez **10 à 25 minutes** de boot et de cloud-init.

### 10.1 Image et flavor (AIO)

```bash
cd /root
wget -O jammy.img https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img
openstack image create --disk-format qcow2 --container-format bare \
  --file jammy.img ubuntu-22.04
rm -f jammy.img

openstack flavor create --vcpus 2 --ram 2048 --disk 10 m1.lab
```

L'hyperviseur dispose de 30 Go de disque pour l'ensemble des instances : gardez des flavors de 10 Go ou moins.

### 10.2 cloud-init : mise à jour + nginx (AIO)

```bash
cat > /root/user-data-nginx.yaml <<'EOF'
#cloud-config
bootcmd:
  - [systemctl, mask, --now, snapd.service, snapd.seeded.service, snapd.socket]
package_update: true
package_upgrade: false
packages:
  - nginx
runcmd:
  - echo "nginx installé via apt depuis une VM Nova" > /var/www/html/index.html
  - systemctl enable --now nginx
EOF

openstack server create \
  --image ubuntu-22.04 --flavor m1.lab --network private \
  --security-group web-ssh-icmp --key-name lab-key \
  --user-data /root/user-data-nginx.yaml \
  --wait ubuntu-test

FIP2=$(openstack floating ip create "$EXT_NET" -f value -c floating_ip_address)
openstack server add floating ip ubuntu-test "$FIP2"
echo "Floating IP Ubuntu : $FIP2"

# suivre cloud-init
openstack console log show ubuntu-test | tail -20
```

### ✅ Contrôle n°9 (poste)

```powershell
curl.exe http://192.168.57.1yy               # → nginx installé via apt depuis une VM Nova
ssh -i $HOME\.ssh\lab_nova ubuntu@192.168.57.1yy
```

Dans la VM Ubuntu :

```bash
sudo apt-get update && sudo apt-get -y upgrade
```

---

## 11. Nettoyage (AIO)

```bash
for S in cirros-test ubuntu-test; do
  for IP in $(openstack floating ip list --port $(openstack port list --server $S -f value -c ID) -f value -c "Floating IP Address"); do
    openstack server remove floating ip $S $IP
    openstack floating ip delete $IP
  done
  openstack server delete --wait $S
done
```

La passerelle (§7) et le security group (§8) restent en place pour les TP suivants.

**Terraform** : la `floating_ip` sortie par `terraform apply` est joignable directement depuis le poste. Ajoutez au security group de votre `main.tf` les mêmes règles qu'au §8.1 (ICMP, 22, 80).

---

## 12. Dépannage

| Symptôme | Cause | Correction |
|---|---|---|
| `ping 192.168.56.10` muet | Carte 2 sur le mauvais adaptateur, ou réseau n°1 absent | §2.1, §4, contrôle n°2 |
| `ping 192.168.57.254` muet depuis le poste | Promiscuité absente sur la carte 3, ou carte 3 sur l'adaptateur `.56` | Contrôle n°2 : `nicpromisc3="allow-all"`, `hostonlyadapter3` = adaptateur `.57`, puis redémarrer la VM |
| `br-ex` sans IP après un reboot | Service non activé, ou OVS pas encore prêt | `systemctl status nova-egress` ; `systemctl restart nova-egress` |
| Route du routeur toujours `via 192.168.57.1` | Agent L3 pas resynchronisé | `docker restart neutron_l3_agent` puis contrôle n°5 |
| Ping 8.8.8.8 depuis le routeur KO, route OK | NAT ou FORWARD absent | `iptables -t nat -S POSTROUTING` ; `iptables -S FORWARD \| head` ; relancer `nova-egress.sh` |
| VM : `ping 8.8.8.8` OK, mais `apt` échoue sur la résolution de noms | Pas de DNS sur le subnet `private` | §7.4, puis reboot de la VM |
| `apt-get install` → erreurs 404 | Index embarqués périmés | `sudo apt-get update` d'abord |
| Floating IP : ping OK mais SSH/HTTP refusés | Security group sans règle 22/80, ou mauvais projet | §8.1 dans le projet de la VM |
| `ssh` : `REMOTE HOST IDENTIFICATION HAS CHANGED` | Floating IP réutilisée par une nouvelle VM | `ssh-keygen -R 192.168.57.1xx` |
| Ubuntu injoignable après 5 min | Boot lent en émulation QEMU | Attendre ; `openstack console log show ubuntu-test` |
| Erreur VT-x/AMD-V au démarrage | Hyper-V/WSL2 occupe la virtualisation | PowerShell admin : `bcdedit /set hypervisorlaunchtype off`, puis redémarrer le PC |
| Hôte Linux : VirtualBox refuse `192.168.57.1` | Restriction `/etc/vbox/networks.conf` | Ajouter `* 192.168.56.0/21` |

---

## 13. Intégrer la passerelle dans l'OVA (Vagrant)

Pour que les apprenants n'aient pas à faire le §7, ajoutez `scripts/04-nova-egress.sh` (fourni) au projet Vagrant, puis déclarez-le **après** `03-init-lab.sh` dans le `Vagrantfile` :

```ruby
  config.vm.provision "shell", path: "scripts/01-bootstrap.sh"
  config.vm.provision "shell", path: "scripts/02-deploy-kolla.sh"
  config.vm.provision "shell", path: "scripts/03-init-lab.sh"
  config.vm.provision "nova-egress", type: "shell", path: "scripts/04-nova-egress.sh"
```

Appliquer sur la VM déjà déployée, sans tout reprovisionner (machine de build) :

```powershell
vagrant provision --provision-with nova-egress
```

La sortie doit se terminer par `default via 192.168.57.254 dev qg-…`, puis 3 réponses au ping de `8.8.8.8` et `OK : VMs Nova joignables…`.

Réexporter ensuite l'OVA (VM éteinte) :

```powershell
vagrant halt
& "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" export "openstack-aio-kolla" -o openstack-aio-kolla.ova --ovf20
```

Ce qui est conservé dans l'OVA : le service `nova-egress` (activé au boot), la gateway `192.168.57.254` et les DNS (stockés en base Neutron), et le security group `web-ssh-icmp`. Les réseaux host-only du poste ne sont pas exportés, il faut toujours les créer (§2).
