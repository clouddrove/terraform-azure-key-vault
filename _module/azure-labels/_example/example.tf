
provider "azurerm" {
  features {}
}

module "labels" {
  source = ".."

  name          = "labels"
  environment   = "staging"
  label_order   = ["name", "environment"]
  business_unit = "Corp"
  attributes    = ["private"]
  extra_tags = {
    Application = "Testing"
  }
}
