# Démo Terraform — Multi-environnements par WORKSPACES (dev / staging / prod)

Même infrastructure que `5-demo-environnements` (réseau + security group +
VM CirrOS avec IP flottante, le tout en modules), mais organisée
autrement : **un seul dossier de code**, et c'est le **workspace Terraform**
sélectionné qui détermine l'environnement.

À présenter **après** `5-demo-environnements` : les deux démos déploient la
même chose, seule l'organisation change. C'est la comparaison qui est
intéressante.

## Structure

```
5-demo-environnements-workspaces/
├── README.md
├── modules/              <- les mêmes briques : compute, network, security
├── backend.tf            <- UN seul backend pour tous les envs
├── provider.tf
├── versions.tf
├── variables.tf          <- uniquement ce qui est COMMUN
├── terraform.tfvars      <- valeurs communes (cloud, image, réseau externe...)
├── locals.tf             <- LA différence entre les envs : une map par workspace
├── main.tf               <- garde-fou + appel des 3 modules
├── outputs.tf
└── clouds.yaml
```

Pas de dossier `envs/`, pas de `stack/` : tout est au même endroit.

## Comment ça marche

### 1. `terraform.workspace` choisit les valeurs

`locals.tf` contient une map avec une entrée par environnement :

```hcl
locals {
  envs = {
    dev     = { subnet_cidr = "10.60.1.0/24", flavor_name = "m1.tiny", ssh_allowed_cidr = "0.0.0.0/0" }
    staging = { subnet_cidr = "10.60.2.0/24", flavor_name = "m1.tiny", ssh_allowed_cidr = "0.0.0.0/0" }
    prod    = { subnet_cidr = "10.60.3.0/24", flavor_name = "m1.tiny", ssh_allowed_cidr = "192.168.57.0/24" }
  }
  env    = local.envs[terraform.workspace]   # (simplifié, voir locals.tf)
  prefix = "ws-${terraform.workspace}"
}
```

`terraform.workspace` vaut le nom du workspace sélectionné. Le code utilise
ensuite `local.env.subnet_cidr`, `local.env.flavor_name`, etc.

### 2. Un état par workspace, sous le même backend

Avec le backend `local`, Terraform range les états ainsi :

```
terraform.tfstate.d/
├── dev/terraform.tfstate
├── staging/terraform.tfstate
└── prod/terraform.tfstate
```

Détruire dev ne touche pas prod : chaque workspace a son propre état.

### 3. Le garde-fou sur `default`

Il existe toujours un workspace `default`. Sans précaution, un `apply`
oublié dedans créerait un environnement `ws-default`. `main.tf` l'empêche
avec une **précondition** :

```
Error: Resource precondition failed
Workspace "default" inconnu : faites terraform workspace select dev | staging | prod.
```

## Exécution

```bash
cd 5-demo-environnements-workspaces
terraform init
```

Créer les workspaces (une seule fois) :

```bash
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod
terraform workspace list        # l'étoile marque le workspace courant
```

Déployer un environnement :

```bash
terraform workspace select dev
terraform apply
terraform output
```

Puis pareil pour les autres :

```bash
terraform workspace select staging && terraform apply
terraform workspace select prod    && terraform apply
```

Sans changer de workspace sélectionné, on peut aussi viser un workspace
pour une seule commande avec la variable d'environnement `TF_WORKSPACE`
(pratique en CI) :

```bash
TF_WORKSPACE=prod terraform plan
```

En PowerShell :

```powershell
$env:TF_WORKSPACE = "prod"; terraform plan; Remove-Item Env:TF_WORKSPACE
```

Nettoyage, workspace par workspace :

```bash
terraform workspace select dev && terraform destroy
terraform workspace select staging && terraform destroy
terraform workspace select prod && terraform destroy
terraform workspace select default
terraform workspace delete dev
terraform workspace delete staging
terraform workspace delete prod
```

`terraform workspace delete` refuse de supprimer un workspace dont l'état
contient encore des ressources : il faut d'abord faire le `destroy`.

## Ce qui distingue les environnements

| Paramètre | dev | staging | prod |
|-----------|-----|---------|------|
| CIDR | 10.60.1.0/24 | 10.60.2.0/24 | 10.60.3.0/24 |
| Flavor | m1.tiny | m1.tiny | m1.tiny (m1.small visé, limité par le disque du lab) |
| SSH autorisé depuis | 0.0.0.0/0 | 0.0.0.0/0 | 192.168.57.0/24 uniquement |
| Préfixe des ressources | `ws-dev-` | `ws-staging-` | `ws-prod-` |

Le préfixe `ws-` et les CIDR `10.60.x` évitent toute collision avec
`5-demo-environnements` (`dev-`, `10.50.x`) : les deux démos peuvent tourner
en même temps sur le lab.

## Dossiers ou workspaces ?

| | Un dossier par env (`5-demo-environnements`) | Workspaces (cette démo) |
|---|---|---|
| Code | `stack/` commun + un petit dossier par env | Un seul dossier |
| Ce qui varie | Un `terraform.tfvars` par env | Une map dans `locals.tf` |
| État | Un backend par dossier | Un backend, un état par workspace |
| Choix de l'env | Le dossier où l'on se trouve (visible) | `terraform workspace select` (invisible dans le prompt) |
| Risque principal | Oublier d'appliquer une correction à un env | Appliquer dans le mauvais workspace |
| Backend / identifiants différents par env | Oui (ex. prod dans un autre projet, un autre compte) | Non : même backend, même provider pour tous |
| Backend GitLab (`http`) | Oui | **Non** : le backend `http` ne gère pas les workspaces |

**Recommandation :**
- **Workspaces** : bien adaptés à des environnements **identiques et
  jetables** (une copie par développeur, une branche de feature, des tests),
  qui partagent le même backend et les mêmes droits.
- **Un dossier par environnement** : préférable pour dev / staging / prod.
  Prod a souvent un autre compte, d'autres droits, un autre backend, et
  l'environnement visé se voit dans le chemin. C'est aussi ce que
  recommande la documentation HashiCorp : les workspaces CLI ne sont pas
  faits pour isoler des environnements qui demandent des identifiants ou
  des contrôles d'accès différents.

## Prérequis

- Lab OpenStack démarré, `terraform` >= 1.5, clé publique `~/.ssh/id_rsa.pub`.
- `clouds.yaml` présent dans le dossier (copie de `../terraform/clouds.yaml`) ;
  adaptez `cloud_name` dans `terraform.tfvars` si vous utilisez une autre
  entrée.
- Les IP flottantes (pool `public`, 192.168.57.100-200) sont joignables
  directement depuis l'hôte, qui a l'adresse 192.168.57.1 sur ce réseau.
- CirrOS : login `cirros`, mot de passe `gocubsgo`.
