terraform {
  backend "azurerm" {
    resource_group_name  = "michelinmohamed"
    storage_account_name = "comptestockagemohamed"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}