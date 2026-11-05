# Démos Terraform — Introduction aux modules

Trois versions de la même infrastructure (celle du TP 1 : VM CirrOS + réseau
privé + routeur + security group + IP flottante), avec un degré de
modularisation croissant. L'objectif : voir **comment et pourquoi** on extrait
du code dans un module.

| Démo | Modules utilisés | Ce qui reste dans le root |
|------|------------------|---------------------------|
| `01-module-compute` | `compute` | réseau, routeur, security group |
| `02-module-reseau` | `compute`, `network` | security group |
| `03-module-security` | `compute`, `network`, `security` | (uniquement la composition) |

## Ce qu'illustre chaque module

- **`compute`** : encapsule keypair + port + VM + IP flottante. Montre les
  entrées/sorties d'un module et l'option `create_floating_ip` (booléen).
- **`network`** : encapsule réseau + sous-réseau + routeur + raccordement.
  Montre qu'un module expose des IDs consommés par un autre module.
- **`security`** : encapsule le security group et ses règles, décrites par
  une **liste d'objets** parcourue avec `for_each`. Montre les types
  complexes (`list(object({...}))` avec `optional()`).

En démo 3, le fichier `main.tf` du root ne contient plus que trois blocs
`module` : c'est de la **composition** — le but final des modules.

## Utilisation

```bash
cd demo-modules/01-module-compute
terraform init      # télécharge le provider ET référence les modules locaux
terraform apply
terraform destroy
```

Remarques :
- Chaque démo est autonome (ses modules sont dans son dossier `modules/`).
- Un changement dans `modules/` nécessite un `terraform init` (sans re-télécharger).
- Chaque module local déclare `required_providers` : indispensable pour les
  providers hors namespace hashicorp (sinon Terraform cherche
  `hashicorp/openstack` qui n'existe pas).
