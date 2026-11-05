# TP 1 — Premiers pas : une VM joignable depuis l'extérieur ★

## Contexte

Vous disposez d'un cloud OpenStack et d'un fichier `clouds.yaml` d'accès.
Le cloud possède déjà un réseau externe nommé `public` (192.168.57.0/24) qui
fournit les IP flottantes. **Tout le reste est à créer par vous, avec
Terraform uniquement** — aucune action manuelle dans Horizon.

## Objectif

Déployer une VM CirrOS accessible en SSH depuis la machine hôte via une IP
flottante.

## Ce que votre code doit créer

1. Un **réseau privé** qui vous appartient, avec un **sous-réseau**
   `10.10.1.0/24` (DNS : 8.8.8.8).
2. Le nécessaire pour que ce réseau soit **relié au réseau externe** `public`
   (à vous de trouver quelle ressource OpenStack assure ce rôle).
3. Un **security group** dédié qui autorise uniquement :
   - SSH (TCP 22) depuis n'importe où,
   - ping (ICMP) depuis n'importe où.
4. Une **keypair** à partir de votre clé publique `~/.ssh/id_rsa.pub`.
5. Une **VM** : image `cirros`, flavor `m1.tiny`, connectée à votre réseau
   privé avec le security group ci-dessus.
6. Une **IP flottante** prise dans `public`, associée à la VM.

## Contraintes de structure (imposées)

- Fichiers séparés : `versions.tf`, `provider.tf`, `variables.tf`,
  `terraform.tfvars`, `locals.tf`, `main.tf`, `outputs.tf`
  (+ `data.tf` si vous référencez de l'existant).
- **Aucune valeur en dur dans `main.tf`** : tout passe par des variables
  (déclarées avec type + description) ou des locals.
- Toutes les ressources sont nommées avec le préfixe `tp1-`, construit via
  un **local** (le préfixe n'apparaît qu'à UN seul endroit du code).
- Le nom du cloud (`clouds.yaml`), l'image, le flavor, le CIDR et le chemin
  de la clé publique sont des **variables** avec valeur dans
  `terraform.tfvars`.

## Sorties attendues (`terraform output`)

| Output | Contenu |
|--------|---------|
| `ip_privee` | l'IP fixe de la VM sur votre réseau |
| `ip_flottante` | l'IP flottante associée |
| `ssh` | la commande SSH prête à copier-coller |

## Critères de validation

- [ ] `terraform validate` passe.
- [ ] `terraform apply` crée l'ensemble en une seule fois, sans erreur.
- [ ] La VM est `ACTIVE` et le ping vers l'IP flottante répond
      (depuis l'hôte, selon votre configuration réseau VirtualBox).
- [ ] La connexion SSH `cirros@<ip_flottante>` fonctionne.
- [ ] `terraform destroy` supprime tout, sans reste dans Horizon.

## Indices (pas de code !)

- La documentation du provider :
  https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs
- Le réseau externe existe déjà : il se **référence**, il ne se crée pas.
- Demandez-vous par où transite un paquet qui va de votre réseau privé vers
  l'extérieur.
