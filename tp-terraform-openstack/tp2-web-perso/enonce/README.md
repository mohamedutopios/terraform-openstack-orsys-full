# TP 2 — Serveur web personnalisé ★★

## Contexte

Même cloud que le TP 1. Cette fois, rien d'utilisable n'existe : ni l'image,
ni le flavor dont vous avez besoin. Vous allez tout créer, y compris le
contenu servi par la VM — **entièrement avec Terraform**, zéro action
manuelle, zéro connexion SSH pour configurer quoi que ce soit.

## Objectif

Déployer un serveur web **Ubuntu 22.04** qui affiche une page HTML
**personnalisée avec votre nom**, générée par Terraform, servie par nginx
installé automatiquement au premier démarrage. Un volume de données est
attaché à la VM.

## Ce que votre code doit créer

1. Tout le socle réseau du TP 1 : réseau privé (`10.10.2.0/24`),
   raccordement à `public`, keypair, IP flottante.
2. Un **security group** autorisant HTTP (TCP 80), SSH (TCP 22) et ICMP.
3. Une **image Glance** `Ubuntu 22.04`, créée par Terraform à partir de
   l'URL officielle Ubuntu Cloud Images :
   `https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img`
4. Un **flavor** sur mesure : 2 vCPU, 2048 Mo de RAM, 10 Go de disque
   (la création de flavor demande le rôle admin — utilisez le cloud admin).
5. Un **volume** de 1 Go, attaché à la VM.
6. La **VM**, construite sur VOTRE image et VOTRE flavor, qui au premier
   boot — sans aucune intervention humaine — installe nginx et sert une page
   d'accueil contenant :
   - votre nom (variable `student_name`),
   - un message (variable `welcome_message`),
   - le nom de la VM.

## Contraintes de structure (imposées)

- Mêmes règles de séparation de fichiers que le TP 1.
- La configuration de premier démarrage est un **template externe** dans
  `templates/` (extension `.tftpl`), rendu avec **`templatefile()`** — pas de
  heredoc géant dans `main.tf`.
- `student_name` et `welcome_message` sont des variables (valeurs dans
  `terraform.tfvars`).
- Préfixe `tp2-` via un local, comme au TP 1.

## Sorties attendues

| Output | Contenu |
|--------|---------|
| `ip_flottante` | l'IP flottante de la VM |
| `url` | l'URL http:// à ouvrir dans le navigateur |
| `volume_peripherique` | le périphérique du volume vu par la VM (ex. /dev/vdb) |
| `ssh` | la commande SSH (login `ubuntu`) |

## Critères de validation

- [ ] `terraform validate` passe.
- [ ] `terraform apply` réussit du premier coup (image + flavor + VM + volume).
- [ ] Après le boot (~3-8 min sous QEMU), la page http répond et contient
      votre nom — sans que vous ayez ouvert un seul SSH.
- [ ] Le volume est visible attaché dans Horizon.
- [ ] `terraform destroy` supprime tout, y compris l'image et le flavor.

## Indices (pas de code !)

- Cherchez comment une VM peut recevoir des instructions exécutées à son
  premier démarrage (le mécanisme standard des images cloud).
- `templatefile()` accepte des variables qui s'interpolent dans le fichier
  avec `${...}`.
- Attention au piège : dans un template `.tftpl`, un `${...}` destiné au
  shell (et non à Terraform) doit être échappé `$${...}`.
