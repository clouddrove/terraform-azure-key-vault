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

module "resource_group" {
  source  = "clouddrove/resource-group/azure"
  version = "1.0.2"

  name        = "keyapp"
  environment = "test"
  label_order = ["environment", "name", ]
  location    = "Canada Central"
}

module "vnet" {
  source  = "clouddrove/vnet/azure"
  version = "1.0.4"

  name                = "app"
  environment         = "test"
  label_order         = ["name", "environment"]
  resource_group_name = module.resource_group.resource_group_name
  location            = module.resource_group.resource_group_location
  address_spaces      = ["10.30.0.0/16"]
}

module "subnet" {
  source  = "clouddrove/subnet/azure"
  version = "1.2.1"

  name                 = "app"
  environment          = "test"
  label_order          = ["name", "environment"]
  resource_group_name  = module.resource_group.resource_group_name
  location             = module.resource_group.resource_group_location
  virtual_network_name = module.vnet.vnet_name

  #subnet
  subnet_names    = ["subnet1", "subnet2"]
  subnet_prefixes = ["10.30.1.0/24", "10.30.2.0/24"]

  # route_table
  routes = [
    {
      name           = "rt-test"
      address_prefix = "0.0.0.0/0"
      next_hop_type  = "Internet"
    }
  ]
}

module "log-analytics" {
  source                           = "clouddrove/log-analytics/azure"
  version                          = "2.0.0"
  name                             = "app"
  environment                      = "test"
  label_order                      = ["name", "environment"]
  create_log_analytics_workspace   = true
  log_analytics_workspace_sku      = "PerGB2018"
  log_analytics_workspace_id       = module.log-analytics.workspace_id
  resource_group_name              = module.resource_group.resource_group_name
  log_analytics_workspace_location = module.resource_group.resource_group_location
}

#Key Vault
module "vault" {
  source     = "../.."
  depends_on = [module.subnet]

  providers = {
    azurerm.dns_sub  = azurerm.peer, #chagnge this to other alias if dns hosted in other subscription.
    azurerm.main_sub = azurerm
  }

  name                      = "deepanfdcc"
  environment               = "test"
  label_order               = ["name", "environment", ]
  resource_group_name       = module.resource_group.resource_group_name
  location                  = module.resource_group.resource_group_location
  reader_objects_ids        = [data.azurerm_client_config.current_client_config.object_id]
  admin_objects_ids         = [data.azurerm_client_config.current_client_config.object_id]
  virtual_network_id        = module.vnet.vnet_id
  subnet_id                 = module.subnet.default_subnet_id[0]
  enable_rbac_authorization = true
  network_acls = {
    bypass         = "AzureServices"
    default_action = "Deny"
    ip_rules       = ["1.2.3.4/32"]
  }
  #private endpoint
  enable_private_endpoint = true
  ########Following to be uncommnented only when using DNS Zone from different subscription along with existing DNS zone.

  # diff_sub = true
  # alias                                         = ""
  # alias_sub                                     = ""

  #########Following to be uncommmented when using DNS zone from different resource group or different subscription.
  # existing_private_dns_zone                     = "privatelink.vaultcore.azure.net"
  # existing_private_dns_zone_resource_group_name = "dns-rg"

  #### enable diagnostic setting
  diagnostic_setting_enable  = true
  log_analytics_workspace_id = module.log-analytics.workspace_id ## when diagnostic_setting_enable enable,  add log analytics workspace id
}
