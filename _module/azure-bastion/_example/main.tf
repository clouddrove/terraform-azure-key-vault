provider "azurerm" {
  features {}
}

module "resource_group" {
  source = "./../../../_modules/resource-group"

  label_order = ["name", "environment", ]
  app_name    = "ota"
  environment = "staging"
  location    = "Canada Central"
}

module "vnet" {
  depends_on = [module.resource_group]
  source     = "./../../../_modules/azure-networking"

  label_order = ["name", "environment"]

  app_name            = "ota"
  environment         = "staging"
  resource_group_name = module.resource_group.resource_group_name
  address_space       = ["10.30.0.0/22"]
  enable_ddos_pp      = false

  #subnets
  subnet_address_prefixes       = ["10.30.0.0/24"]
  disable_bgp_route_propagation = false

  # routes
  enabled_route_table = true

  routes = [
    {
      name                   = "rt-ota-staging"
      address_prefix         = "0.0.0.0/0"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = "10.20.0.4"
    }
  ]

  # peering
  enabled_peering = false

}

module "bastion" {
  depends_on                          = [module.resource_group]
  source                              = "./../"
  label_order                         = ["name", "environment"]
  app_name                            = "ota"
  environment                         = "staging"
  resource_group_name                 = module.resource_group.resource_group_name
  azure_bastion_subnet_address_prefix = ["10.30.2.0/24"]
  virtual_network_name                = module.vnet.name
}
