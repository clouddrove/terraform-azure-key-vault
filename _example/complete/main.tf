provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current_client_config" {}

module "vault" {
  source = "../.."

  name                      = "anfdcc"
  environment               = "test"
  label_order               = ["name", "environment", ]
  resource_group_name       = "*****"
  location                  = "*****"
  reader_objects_ids        = [data.azurerm_client_config.current_client_config.object_id]
  admin_objects_ids         = [data.azurerm_client_config.current_client_config.object_id]
  virtual_network_id        = "*****"
  subnet_id                 = "*****"
  enable_rbac_authorization = true
  network_acls = {
    bypass         = "AzureServices"
    default_action = "Deny"
    ip_rules       = ["1.2.3.4/32"]
  }
  enable_private_endpoint   = false
  diagnostic_setting_enable = false
}
