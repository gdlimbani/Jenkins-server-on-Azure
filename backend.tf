terraform {
  backend "azurerm" {
    resource_group_name = "gdl"
    storage_account_name = "gdlterraform"
    container_name       = "terraformstate"
    key                  = "jenkins-server-terraform.tfstate"
  }
}