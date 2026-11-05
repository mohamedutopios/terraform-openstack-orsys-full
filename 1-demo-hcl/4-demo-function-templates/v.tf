# function :

variable "username" {
  default = "mohamed"
}

output "formatted_username" {
  value = upper(format("user-%s", var.username))
}

variable "list1" {
  default = ["a", "b"]
}

variable "list2" {
  default = ["c", "d"]
}

output "concatenated_list" {
  value = concat(var.list1, var.list2)
}

output "joined_list" {
  value = join(", ", concat(var.list1, var.list2))
}

output "list_length" {
  value = length(concat(var.list1, var.list2))
}

# templates : 

variable "user_name" {
  default = "Mohamed"
}

variable "account_name" {
  default = "Terraform-Prod"
}

variable "env_name" {
  default = "production"
}

output "message_rendered" {
  value = templatefile("message.tpl", {
    name    = var.user_name
    account = var.account_name
    env     = var.env_name
  })
}


variable "servers_list" {
  default = [
    { name = "web01", ip = "10.0.0.1" },
    { name = "db01", ip = "10.0.0.2" }
   
  ]
}

output "servers_info" {
  value = templatefile("servers.tpl", {
    servers = var.servers_list
  })
}