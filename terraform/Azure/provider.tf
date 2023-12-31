terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.77.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "GS-IaC"
    storage_account_name = "memorialonga"
    container_name       = "tchelo"
    key                  = "terraform.tchelo"
  }
}



provider "azurerm" {
  features {}
  skip_provider_registration = true
  alias                      = "cloud"
}