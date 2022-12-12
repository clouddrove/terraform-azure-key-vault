provider "azurerm" {
  features {}
}

module "resource_group" {
  source = "../"

  environment = "staging"
  label_order = ["name", "environment", ]

  name     = "example"
  location = "West US"
}
