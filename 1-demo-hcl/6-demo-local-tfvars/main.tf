locals {
  upper_env     = upper(var.env)
  full_location = "${var.region}-${var.env}"
  common_tags   = merge(var.tags, {
    environment = var.env
    created_by  = "terraform"
  })
  is_prod = var.env == "prod"
}

# null_resource avec interpolation locale simple
resource "null_resource" "print_env" {
  provisioner "local-exec" {
    command = "echo 'Deploying in ${local.full_location}'"
  }
}

# null_resource avec boucle sur la liste d'instances
resource "null_resource" "instances" {
  count = length(var.instances)

  provisioner "local-exec" {
    command = "echo 'Creating instance: ${var.instances[count.index]} in ${local.full_location}'"
  }

  triggers = {
    instance_name = var.instances[count.index]
    env           = var.env
  }
}

# null_resource conditionnel
resource "null_resource" "prod_warning" {
  count = local.is_prod ? 1 : 0

  provisioner "local-exec" {
    command = "echo '⚠️  Production deployment in progress... Apply caution!'"
  }
}