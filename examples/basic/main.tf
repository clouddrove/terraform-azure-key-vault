provider "azurerm" {
  features {}
  subscription_id = "000000-11111-1223-XXX-XXXXXXXXXXXX"
}

provider "azurerm" {
  features {}
  alias           = "peer"
  subscription_id = "000000-11111-1223-XXX-XXXXXXXXXXXX" #change this to other subscription if dns hosted in other subscription.
}

data "azurerm_client_config" "current_client_config" {}

module "vault" {
  source = "../.."

  providers = {
    azurerm.dns_sub  = azurerm.peer, #chagnge this to other alias if dns hosted in other subscription.
    azurerm.main_sub = azurerm
  }

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
