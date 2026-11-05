variable "var_2" {
    description = "seconde variable"
    type = string
    default = "default value for seconde variable"
  
}

output "output_var_2" {
  value = var.var_2
}

output "output_var_1" {
    value = var.var_1
}

output "output_sub_props" {
    value = var.first_object.props3.sub_props
}

output "variables_demo" {
    value = {
        count = var.vm_count
        backup = var.enable_backup
        tags = var.vm_tags
        subnet = var.subnets[0]
    }
  
}