# Démo Terraform — Multi-environnements (dev / staging / prod)

Même infrastructure que `4-demo-modules/03-module-security` (réseau + security
group + VM CirrOS avec IP flottante, le tout en modules), déclinée en
**trois environnements isolés** : `dev`, `staging`, `prod`.

Variante avec **workspaces Terraform** (un seul dossier, l'environnement
choisi par `terraform workspace select`) : `../5-demo-environnements-workspaces`.

## Structure

```
5-demo-environnements/
├── README.md
├── modules/                  <- les briques : compute, network, security
├── stack/                    <- LA COMPOSITION COMMUNE, écrite une fois
│   ├── main.tf               <- assemble les 3 modules (locals, data inclus)
│   ├── variables.tf          <- tout ce qui peut varier entre envs
│   └── outputs.tf
└── envs/
    ├── dev/                  <- un dossier = un environnement, réduit au minimum
    │   ├── backend.tf        <- où vit l'ÉTAT de cet env (non factorisable)
    │   ├── provider.tf       <- configuration du provider (root uniquement)
    │   ├── versions.tf
    │   ├── variables.tf      <- déclarations (nécessaires pour lire le tfvars)
    │   ├── terraform.tfvars  <- LA différence entre les envs est ICI
    │   ├── main.tf           <- ~10 lignes : appelle ../../stack
    │   ├── outputs.tf        <- ré-expose les sorties du stack
    │   └── clouds.yaml
    ├── staging/              <- mêmes fichiers, tfvars différent
    └── prod/                 <- mêmes fichiers, tfvars différent
```

## Les principes illustrés

1. **Un dossier par environnement = un état par environnement.** Chaque env a
   son propre `terraform.tfstate` (voir `backend.tf`) : détruire dev ne
   touche jamais prod. C'est l'isolation la plus forte, plus simple à
   raisonner que les workspaces.
2. **Le code commun n'existe qu'une fois : dans `stack/`.** Les envs sont des
   « shims » de quelques lignes ; impossible de corriger dev en oubliant
   prod. Ce qui varie est dans `terraform.tfvars` : CIDR, flavor, SSH.
3. **La promotion d'un changement est explicite** : on modifie `stack/`, puis
   on `apply` env par env — dev d'abord, prod en dernier. Contrepartie
   assumée : un env ne peut pas diverger structurellement ; toute différence
   passe par une variable du stack (visible et volontaire).
4. **Seul l'irréductible est dupliqué** : `backend.tf` (Terraform interdit
   les variables dans un backend), `provider.tf`/`versions.tf` (config de
   root) et le duo `variables.tf`+`tfvars` (un tfvars n'est lu que via des
   déclarations dans le root).
Par défaut le backend est `local` (testable sans aucun compte externe).

## Backend GitLab (état distant managé)

GitLab héberge nativement les états Terraform (backend `http` + verrouillage
+ visualisation dans **Operate → Terraform states**). Chaque dossier d'env
contient un `backend-gitlab.tf.example` prêt à l'emploi, avec un **nom
d'état par environnement** (`dev`, `staging`, `prod`) — même isolation que
le backend local, mais partagée en équipe et verrouillée.

Activation (détail complet en tête de chaque fichier .example) :

1. `backend.tf` : supprimer le bloc `backend "local"`.
2. Renommer `backend-gitlab.tf.example` → `backend-gitlab.tf` et remplacer
   `<PROJECT_ID>` par l'ID de votre projet GitLab.
3. Identifiants **hors du code**, via variables d'environnement :
   `TF_HTTP_USERNAME` (votre username) et `TF_HTTP_PASSWORD` (un Personal
   Access Token avec le scope `api`).
4. `terraform init -migrate-state` — l'état local existant est migré vers
   GitLab.

Pour un GitLab auto-hébergé, remplacez `gitlab.com` par votre domaine.

## Ce qui distingue les environnements

| Paramètre | dev | staging | prod |
|-----------|-----|---------|------|
| CIDR | 10.50.1.0/24 | 10.50.2.0/24 | 10.50.3.0/24 |
| Flavor | m1.tiny | m1.tiny | m1.tiny (m1.small visé, limité par le disque du lab) |
| SSH autorisé depuis | 0.0.0.0/0 | 0.0.0.0/0 | 192.168.57.0/24 uniquement |
| Préfixe des ressources | `dev-` | `staging-` | `prod-` |

Les trois environnements peuvent être déployés **en même temps** (CIDR et
noms distincts).

## Exécution

Toujours se placer **dans le dossier de l'environnement** visé :

```bash
cd 5-demo-environnements/envs/dev
terraform init
terraform plan
terraform apply
terraform output
```

Puis pareil pour `staging` et `prod` (chacun son cycle, chacun son état) :

```bash
cd ../staging && terraform init && terraform apply
```

```bash
cd ../prod && terraform init && terraform apply
```

Nettoyage — env par env, l'ordre n'importe pas :

```bash
terraform destroy
```

## Prérequis

- Lab OpenStack démarré, `terraform` >= 1.5, clé publique `~/.ssh/id_rsa.pub`.
- Chaque dossier d'env contient son `clouds.yaml` (copie de
  `../../../terraform/clouds.yaml`) ; adaptez `cloud_name` dans le tfvars si
  vous utilisez une autre entrée.
- Les IP flottantes (pool `public`, 192.168.57.100-200) sont joignables
  directement depuis l'hôte, qui a l'adresse 192.168.57.1 sur ce réseau.
