variable "var_1" {
    description = "first variable"
    type = string
    default = "default value for first variable" 
}


variable "first_object" {
    description = "first object"
    type = object({
      props1 = string
      props2 = string
      props3 = object({
        sub_props = string
      })
    })
    default = {
      props1 = "value1"
      props2 = "value2"
      props3 = {
        sub_props = "value3"
      }
    }
  
}

variable "vm_count" {
    description = "Le nombre de variables"
    type = number
    default = 3
}


variable "enable_backup" {
    type = bool
    description = "Activer le backup de la VM"
    default = false
}

variable "vm_tags" {
    type = map(string)
    description = "Tags pour la vm"
    default = {
      "environnement" = "dev"
      "owner" = "admin"
    }
  
}

variable "subnets" {
    type = list(string)
    description = "Liste de sous-reseau"
    default = [ "subnet-1","subnet-2" ]
}

