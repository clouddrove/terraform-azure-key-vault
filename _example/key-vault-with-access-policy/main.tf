provider "azurerm" {
  features {}
}

module "resource_group" {
  source  = "clouddrove/resource-group/azure"
  version = "1.0.1"

  name        = "app"
  environment = "test"
  label_order = ["name", "environment"]
  location    = "Canada Central"
}


#Vnet
module "vnet" {
  source  = "clouddrove/vnet/azure"
  version = "1.0.1"

  name                = "app"
  environment         = "test"
  label_order         = ["name", "environment"]
  resource_group_name = module.resource_group.resource_group_name
  location            = module.resource_group.resource_group_location
  address_space       = "10.0.0.0/16"
}

module "subnet" {
  source  = "clouddrove/subnet/azure"
  version = "1.0.1"

  name                 = "app"
  environment          = "test"
  label_order          = ["name", "environment"]
  resource_group_name  = module.resource_group.resource_group_name
  location             = module.resource_group.resource_group_location
  virtual_network_name = join("", module.vnet.vnet_name)

  #subnet
  default_name_subnet = true
  subnet_names        = ["subnet1"]
  subnet_prefixes     = ["10.0.1.0/24"]

  # route_table
  enable_route_table = false
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
  version                          = "1.0.1"
  name                             = "app"
  environment                      = "test"
  label_order                      = ["name", "environment"]
  create_log_analytics_workspace   = true
  log_analytics_workspace_sku      = "PerGB2018"
  resource_group_name              = module.resource_group.resource_group_name
  log_analytics_workspace_location = module.resource_group.resource_group_location
}

#Key Vault
module "vault" {
  depends_on = [module.resource_group, module.vnet]
  source     = "./../.."

  name        = "annkkdsovvdcc"
  environment = "test"
  label_order = ["name", "environment", ]

  resource_group_name = module.resource_group.resource_group_name

  virtual_network_id = module.vnet.vnet_id[0]
  subnet_id          = module.subnet.default_subnet_id[0]

  #### enable diagnostic setting
  diagnostic_setting_enable  = true
  log_analytics_workspace_id = module.log-analytics.workspace_id ## when diagnostic_setting_enable enable,  add log analytics workspace id

  #access_policy
  access_policy = [
    {
      object_id = ""
      key_permissions = [
        "Get",
        "List",
        "Update",
        "Create",
        "Import",
        "Delete",
        "Recover",
        "Backup",
        "Restore",
        "UnwrapKey",
        "WrapKey",
        "GetRotationPolicy"
      ]
      certificate_permissions = [
        "Get",
        "List",
        "Update",
        "Create",
        "Import",
        "Delete",
        "Recover",
        "Backup",
        "Restore",
        "ManageContacts",
        "ManageIssuers",
        "GetIssuers",
        "ListIssuers",
        "SetIssuers",
        "DeleteIssuers"
      ]
      secret_permissions = [
        "Get",
        "List",
        "Set",
        "Delete",
        "Recover",
        "Backup",
        "Restore"
      ]
      storage_permissions = []

    }
  ]
}
