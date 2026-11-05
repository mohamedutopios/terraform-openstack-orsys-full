# Démos Terraform — OpenStack AIO (Kolla)

Cinq démos progressives, chacune **autonome** (son propre état Terraform et son
propre `clouds.yaml`). Toutes ont été testées (`init` → `apply` → `destroy`)
contre le lab.

| Démo | Contenu | Notions |
|------|---------|---------|
| `01-premiere-vm` | 1 VM CirrOS sur le réseau `private` + IP flottante | data sources, keypair, port, instance, floating IP |
| `01-vm-template` | Variante de la 01 : VM Ubuntu configurée au 1er boot (nginx + page générée) | image Glance, `user_data`, `templatefile()`, template cloud-init `.tftpl` (interpolation, boucle `for`, échappement `$${}`) |
| `02-reseau-dedie` | Réseau/sous-réseau/routeur dédiés + security group + VM | ressources réseau Neutron complètes |
| `03-volume-cinder` | VM + volume Cinder 1 Go attaché | stockage bloc, attachement |
| `04-swift-objets` | Conteneur Swift + objets uploadés | stockage objet |
| `05-multi-vm` | N VMs identiques (variable `vm_count`) | count, variables, outputs en liste |

## Structure des fichiers

Chaque démo suit la même organisation standard :

```
<demo>/
├── versions.tf        # Contraintes Terraform + providers
├── provider.tf        # Configuration du provider OpenStack
├── variables.tf       # Déclaration des variables (types, descriptions, défauts)
├── terraform.tfvars   # Valeurs des variables (chargé automatiquement)
├── locals.tf          # Valeurs calculées (préfixes, conventions de nommage)
├── data.tf            # Ressources existantes référencées (data sources)
├── main.tf            # Les ressources créées par la démo
├── outputs.tf         # Sorties affichées après apply
└── clouds.yaml        # Identifiants du cloud (copié depuis ../terraform/)
```

`terraform.tfvars` est lu automatiquement par Terraform : c'est là qu'on
adapte un déploiement (nombre de VMs, CIDR, image...) sans toucher au code.

## Utilisation

```bash
cd demo-terraform/01-premiere-vm
terraform init
terraform apply
# ... regarder les outputs, tester (ping/ssh) ...
terraform destroy
```

## Prérequis

- Le lab OpenStack démarré (Horizon répond sur http://192.168.56.250)
- Une clé publique SSH dans `~/.ssh/id_rsa.pub` (démos 1, 2, 3, 5)
- Le `clouds.yaml` présent dans chaque dossier de démo. Il est copié depuis
  `../terraform/clouds.yaml` (généré par le provisioning). Si vous redéployez
  le lab (`vagrant destroy && vagrant up`), le mot de passe admin change :
  recopiez le nouveau `terraform/clouds.yaml` dans chaque dossier de démo.

## Notes

- Les ressources sont préfixées `demo1-`, `demo2-`, ... : les démos peuvent
  être appliquées en parallèle sans collision.
- CirrOS : login `cirros`, mot de passe `gocubsgo`.
- Les IP flottantes sont prises dans le pool `public` (192.168.57.100-200),
  joignables depuis l'hôte (qui est `192.168.57.1`).
