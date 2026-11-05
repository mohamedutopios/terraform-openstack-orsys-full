variable "demo_condition" {
  description = "value of the condition"
  type = bool
  default = false
}

variable "list_of_strings" {  
    description = "A list of strings"  
    type        = list(string)  
    default     = ["apple", "banana", "cherry"]
}

output "lengths_of_strings" { 
     value = [for s in var.list_of_strings : length(s)]
}

output "output_condition" {
  value = var.demo_condition ? "the condition is true" : "the condition is false"
}

variable "is_production" {
  type    = bool
  default = false
}

output "allowed_ips" {
  value = var.is_production ? ["10.0.0.0/24"] : ["192.168.0.0/24", "172.16.0.0/16"]
}

variable "user_roles" {
  default = {
    alice = "admin"
    bob   = "user"
    carol = "guest"
  }
}

output "formatted_roles" {
  value = [for username, role in var.user_roles : "${username} is ${role}"]
}


variable "items" {
  type    = list(string)
  default = ["item1", "item2"]
}

resource "null_resource" "items_resource" {
  count = length(var.items) > 0 ? length(var.items) : 0

  triggers = {
    item_name = var.items[count.index]
  }
}

output "items_count" {
  value = length(null_resource.items_resource)
  
}

variable "words" {
  default = ["terraform", "cloud", "infra", "devops", "git"]
}

output "long_words" {
  value = [for word in var.words : word if length(word) > 5]
}

variable "environment" {
  default = "staging"
}

output "env_message" {
  value = var.environment == "prod" ? "Production environment": var.environment == "staging" ? "Staging environment": "Development environment"
}

variable "fruits" {
  default = ["apple", "banana", "cherry"]
}

output "fruit_map" {
  value = { for f in var.fruits : f => upper(f) }
}