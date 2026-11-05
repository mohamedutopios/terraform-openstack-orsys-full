# TP Terraform × OpenStack — Série progressive

Trois TP de difficulté croissante sur le lab OpenStack AIO (Kolla).
Chaque TP contient :

- `enonce/` — le sujet : objectifs, contraintes, critères de validation.
  **Il dit QUOI faire, jamais COMMENT.**
- `solution/` — une solution complète, structurée et testée.

| TP | Difficulté | Ce qu'on mobilise |
|----|-----------|-------------------|
| [tp1-premiers-pas](tp1-premiers-pas/enonce/README.md) | ★ | VM, réseau, sous-réseau, security group (SSH + ICMP), IP flottante, variables/tfvars/locals/outputs |
| [tp2-web-perso](tp2-web-perso/enonce/README.md) | ★★ | + règle HTTP, création d'image Glance, création de flavor, volume attaché, template cloud-init (`templatefile`) |
| [tp3-infra-complete](tp3-infra-complete/enonce/README.md) | ★★★ | Architecture 2 réseaux + routeur, 2 VMs (Ubuntu 18.04 nginx / 22.04), flavor sur mesure, SG croisés, ping inter-réseaux |

## Prérequis (une fois pour toutes)

- Le lab OpenStack démarré (Horizon sur http://192.168.56.250).
- `terraform` >= 1.5 installé sur la machine hôte.
- Un `clouds.yaml` valide **dans le dossier de travail** (les solutions utilisent
  l'entrée `kolla-aio` admin, copiée depuis `../../terraform/clouds.yaml` ;
  adaptez `cloud_name` dans `terraform.tfvars` si vous utilisez votre propre
  entrée/projet).
- Une clé publique SSH dans `~/.ssh/id_rsa.pub`.
- Les instances ont besoin d'Internet (TP2 et TP3 installent des paquets) :
  la carte 3 de la VM OpenStack doit être sur le réseau NAT VirtualBox
  `OpenStackNAT` (192.168.57.0/24, DHCP désactivé).
- Pour joindre une IP flottante depuis l'hôte (SSH, navigateur) : ajouter une
  règle de **redirection de ports IPv4** au réseau NAT
  (ex. `127.0.0.1:2222 → <IP flottante>:22`, `127.0.0.1:8080 → <IP flottante>:80`).

## Conseils

- Les ressources de chaque TP sont préfixées (`tp1-`, `tp2-`, `tp3-`) : les TP
  peuvent cohabiter, mais pensez à `terraform destroy` en fin de TP (le lab a
  des ressources limitées).
- Sous émulation QEMU (pas de KVM), une VM Ubuntu met 10 à 25 minutes à
  booter et finir son cloud-init : soyez patients sur les TP 2 et 3.
  CirrOS (TP1) boote en moins d'une minute.
