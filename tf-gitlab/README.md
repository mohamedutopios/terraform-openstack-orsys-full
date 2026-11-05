# Terraform OpenStack — backend GitLab (GitLab-managed Terraform state) — v1.0

Remplace le backend `s3` (`mohamed-formation` / `openstack/mohamed/terraform.tfstate`) par le state géré par GitLab (backend `http`), avec lock natif.

## Contenu

| Fichier | Rôle |
|---|---|
| `backend.tf` | `backend "http" {}` + provider OpenStack (config par variables d'environnement) |
| `.gitlab-ci.yml` | Pipeline `validate` → `plan` → `apply` (manuel, branche par défaut) |

---

## 0. Prérequis

- Un projet GitLab (gitlab.com ou self-managed) avec le code Terraform poussé dedans.
- Rôle **Developer** minimum sur le projet pour lire/écrire/locker le state (**Maintainer** pour supprimer un state).
- Fonctionnalité Terraform state activée : *Settings → General → Visibility, project features, permissions → Infrastructure* activé.
- Un **Personal Access Token** (scope `api`) pour l'usage en local : *User settings → Access tokens*.
- L'**ID du projet** : visible sur la page d'accueil du projet (sous le nom).
- Terraform ≥ 1.6 en local.
- Pour la migration uniquement : des credentials AWS qui peuvent lire `s3://mohamed-formation/openstack/mohamed/terraform.tfstate`.
- Un runner capable de joindre l'API OpenStack (`OS_AUTH_URL`). Si le cloud OpenStack est privé (lab VirtualBox, réseau d'entreprise), les shared runners gitlab.com ne le joignent pas : il faut un **runner self-managed** dans ce réseau.

## 1. Variables d'environnement en local

```bash
export GITLAB_URL="https://gitlab.com"          # ou l'URL de ton GitLab self-managed
export GITLAB_PROJECT_ID="12345678"             # ID du projet
export GITLAB_USER="ton-username-gitlab"
export GITLAB_TOKEN="glpat-xxxxxxxxxxxxxxxxxxxx"
export TF_STATE_NAME="openstack-mohamed"        # même nom que dans .gitlab-ci.yml

export TF_HTTP_ADDRESS="${GITLAB_URL}/api/v4/projects/${GITLAB_PROJECT_ID}/terraform/state/${TF_STATE_NAME}"
export TF_HTTP_LOCK_ADDRESS="${TF_HTTP_ADDRESS}/lock"
export TF_HTTP_UNLOCK_ADDRESS="${TF_HTTP_ADDRESS}/lock"
export TF_HTTP_LOCK_METHOD="POST"
export TF_HTTP_UNLOCK_METHOD="DELETE"
export TF_HTTP_RETRY_WAIT_MIN="5"
export TF_HTTP_USERNAME="${GITLAB_USER}"
export TF_HTTP_PASSWORD="${GITLAB_TOKEN}"
```

Le backend `http` lit directement ces `TF_HTTP_*` : rien de sensible n'est écrit dans le code ni dans `.terraform/`.

## 2. Migrer le state existant depuis S3

Dans le dossier du projet, `backend.tf` contient encore l'ancien bloc `s3`, et le state est déjà initialisé dessus (`terraform init` fait au moins une fois).

```bash
# 2.1 Sauvegarde locale du state S3
aws s3 cp s3://mohamed-formation/openstack/mohamed/terraform.tfstate ./terraform.tfstate.backup-s3 --region eu-west-3

# 2.2 Remplacer backend.tf par la version GitLab (ce kit)

# 2.3 Migration : Terraform lit le state S3 et l'écrit dans GitLab
terraform init -migrate-state
# répondre "yes" à "Do you want to copy existing state to the new backend?"

# 2.4 Vérification
terraform state list
terraform plan        # doit afficher "No changes."
```

Contrôle côté GitLab : *Operate → Terraform states* → le state `openstack-mohamed` apparaît.

Projet sans state existant : sauter 2.1 et 2.3, et faire seulement `terraform init`.

Après validation, l'ancien objet S3 peut être supprimé :

```bash
aws s3 rm s3://mohamed-formation/openstack/mohamed/terraform.tfstate --region eu-west-3
```

## 3. Variables CI/CD (credentials OpenStack)

*Settings → CI/CD → Variables*, chacune en **Masked** (et **Protected** si `apply` se fait seulement sur des branches protégées).

Avec une application credential (recommandé) :

| Variable | Exemple |
|---|---|
| `OS_AUTH_URL` | `https://keystone.example.org:5000/v3` |
| `OS_REGION_NAME` | `RegionOne` |
| `OS_AUTH_TYPE` | `v3applicationcredential` |
| `OS_APPLICATION_CREDENTIAL_ID` | `...` |
| `OS_APPLICATION_CREDENTIAL_SECRET` | `...` |
| `OS_INTERFACE` | `public` |
| `OS_IDENTITY_API_VERSION` | `3` |

Création de l'application credential :

```bash
openstack application credential create gitlab-ci-terraform --description "Terraform GitLab CI"
```

Avec user / password à la place : `OS_USERNAME`, `OS_PASSWORD`, `OS_PROJECT_NAME`, `OS_USER_DOMAIN_NAME`, `OS_PROJECT_DOMAIN_NAME` (sans `OS_AUTH_TYPE`).

Les variables `TF_HTTP_*` côté CI sont déjà dans `.gitlab-ci.yml` : l'authentification au state se fait avec `CI_JOB_TOKEN`, pas de token à créer.

## 4. Pipeline

```bash
git add backend.tf .gitlab-ci.yml
git commit -m "Terraform: migration du backend S3 vers GitLab-managed state"
git push
```

| Job | Quand | Ce qu'il fait |
|---|---|---|
| `fmt-validate` | chaque push | `terraform fmt -check`, `terraform validate` |
| `plan` | chaque push | `plan.tfplan` + `plan.txt` en artifacts |
| `apply` | branche par défaut, **manuel** | applique exactement le plan du job `plan` |

`resource_group` empêche deux `plan`/`apply` en parallèle sur le même state (en plus du lock du backend).

## 5. Opérations utiles

```bash
# Débloquer un lock resté actif (job annulé en plein apply)
terraform force-unlock <LOCK_ID>

# Télécharger le state courant
curl --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" "${TF_HTTP_ADDRESS}" -o state.json

# Lister les versions du state : Operate → Terraform states → ⋮ → versions
```

## Limites

- `CI_JOB_TOKEN` a les droits de l'utilisateur qui a déclenché le pipeline : un user sans rôle Developer ne peut pas locker/écrire le state.
- Le state est stocké en clair côté GitLab (chiffré au repos par GitLab, mais lisible par tout Developer du projet) : ne pas y mettre de projet dont les secrets ne doivent pas être visibles par toute l'équipe.
- Un state par nom (`TF_STATE_NAME`) : pour du multi-environnement, changer le nom (ex. `openstack-dev`, `openstack-prod`) plutôt que le `key` S3.
