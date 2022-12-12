data "azurerm_resource_group" "default" {
  name = var.resource_group_name
}

locals {
  resource_group_name = data.azurerm_resource_group.default.name
  location            = data.azurerm_resource_group.default.location
}

module "labels" {
  source      = "./../azure-labels"
  name        = var.app_name
  environment = var.environment
  label_order = var.label_order
  extra_tags  = var.tags
}

#---------------------------------------------
# Public IP for Azure Bastion Service
#---------------------------------------------
resource "azurerm_public_ip" "pip" {
  count               = var.enabled ? 1 : 0
  name                = format("%s-bastion-ip", module.labels.id)
  location            = local.location
  resource_group_name = local.resource_group_name
  allocation_method   = var.public_ip_allocation_method
  sku                 = var.public_ip_sku
  tags                = module.labels.tags
}

resource "azurerm_subnet" "main" {
  count                = var.enabled ? 1 : 0
  name                 = "AzureBastionSubnet"
  resource_group_name  = local.resource_group_name
  virtual_network_name = var.virtual_network_name
  address_prefixes     = var.azure_bastion_subnet_address_prefix
}

#---------------------------------------------
# Azure Bastion Service host
#---------------------------------------------
resource "azurerm_bastion_host" "main" {
  count = var.enabled ? 1 : 0

  name                   = format("%s-bastion", module.labels.id)
  location               = local.location
  resource_group_name    = local.resource_group_name
  copy_paste_enabled     = var.enable_copy_paste
  file_copy_enabled      = var.bastion_host_sku == "Standard" ? var.enable_file_copy : null
  sku                    = var.bastion_host_sku
  ip_connect_enabled     = var.enable_ip_connect
  scale_units            = var.bastion_host_sku == "Standard" ? var.scale_units : 2
  shareable_link_enabled = var.bastion_host_sku == "Standard" ? var.enable_shareable_link : null
  tunneling_enabled      = var.bastion_host_sku == "Standard" ? var.enable_tunneling : null
  tags                   = module.labels.tags


  ip_configuration {
    name                 = format("%s-network", module.labels.id)
    subnet_id            = join("", azurerm_subnet.main.*.id)
    public_ip_address_id = join("", azurerm_public_ip.pip.*.id)
  }
}