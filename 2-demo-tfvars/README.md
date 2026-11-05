# Démo — Les tfvars et l'ordre de précédence des variables

Démo sans infrastructure (`null_resource`) : elle montre **toutes les façons
de donner une valeur à une variable** Terraform, et **qui gagne** quand
plusieurs sources définissent la même.

## Les sources, de la plus faible à la plus forte

| # | Source | Chargement |
|---|--------|-----------|
| 1 | `default` dans `variables.tf` | filet de sécurité, utilisé si rien d'autre |
| 2 | Variables d'environnement `TF_VAR_<nom>` | lues automatiquement |
| 3 | `terraform.tfvars` (ou `.tfvars.json`) | chargé automatiquement (nom exact) |
| 4 | `*.auto.tfvars` (ou `.auto.tfvars.json`) | chargés automatiquement, en **ordre alphabétique** (le dernier écrase) |
| 5 | `-var` et `-var-file` sur la commande | le plus fort ; en cas de répétition, le **dernier** sur la ligne gagne |

Un fichier nommé autrement (ex. `dev.tfvars`) n'est **jamais** chargé seul :
il faut `-var-file=dev.tfvars` (c'est le mécanisme de `demo-backend-gitlab/`).

## La démo

- 5 variables, chacune alimentée par UNE source différente (default, env,
  terraform.tfvars, aaa.auto.tfvars, -var).
- 1 variable vedette `qui_gagne`, définie PARTOUT : default,
  terraform.tfvars, aaa.auto.tfvars, zzz.auto.tfvars — et vous pouvez
  ajouter l'env et le -var pour compléter.
- Le `null_resource` a les 6 valeurs en `triggers` : changez n'importe
  quelle source, re-applyez -> la ressource est **remplacée** (preuve que
  la valeur effective a changé).

## À dérouler dans l'ordre

```bash
$env:TF_VAR_var_env = "je viens de l'environnement"
terraform init
terraform apply
terraform output
```

→ `qui_gagne = "4-zzz.auto.tfvars"` : les auto.tfvars battent
terraform.tfvars, et zzz bat aaa (alphabétique).

Ensuite, faites parler la précédence :

```bash
$env:TF_VAR_qui_gagne = "1bis-environnement"
terraform apply
```

→ toujours `4-zzz.auto.tfvars` : l'environnement perd contre TOUT fichier
tfvars (il ne bat que le default).

```bash
terraform apply -var "qui_gagne=5-la-ligne-de-commande"
```

→ `5-la-ligne-de-commande` gagne, et la ressource est remplacée
(le trigger a changé).

```bash
terraform destroy
```

## Les pièges à retenir

- `TF_VAR_` est **sous** les tfvars : pratique pour les secrets et la CI,
  mais silencieusement écrasé si un tfvars définit la même variable.
- Les `*.auto.tfvars` s'appliquent en ordre alphabétique : nommer les
  fichiers, c'est choisir l'ordre (d'où `aaa.` et `zzz.` ici).
- Une variable sans `default` et sans valeur -> prompt interactif (bloquant
  en CI : toujours un default OU une source garantie).
- `-var` en dernier écrase tout : parfait pour un test ponctuel, dangereux
  en usage courant (la valeur n'est tracée nulle part).
