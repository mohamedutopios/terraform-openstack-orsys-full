# Backend GitLab de l'environnement dev — état "null-dev" du projet 84876184.
# Le mot de passe (PAT scope api) n'est JAMAIS ici :
#   PowerShell : $env:TF_HTTP_PASSWORD = "<votre PAT>"
#   bash       : export TF_HTTP_PASSWORD="<votre PAT>"
address        = "https://gitlab.com/api/v4/projects/84876184/terraform/state/null-dev"
lock_address   = "https://gitlab.com/api/v4/projects/84876184/terraform/state/null-dev/lock"
unlock_address = "https://gitlab.com/api/v4/projects/84876184/terraform/state/null-dev/lock"
username       = "mohamed.aijjou1780"
lock_method    = "POST"
unlock_method  = "DELETE"
retry_wait_min = 5
