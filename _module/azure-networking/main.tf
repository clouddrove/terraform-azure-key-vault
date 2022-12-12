
## Vritual Network and Subnet Creation
data "azurerm_resource_group" "default" {
  name = var.resource_group_name
}

locals {
  resource_group_name = data.azurerm_resource_group.default.name
  ddos_pp_id          = var.enable_ddos_pp ? join("", azurerm_network_ddos_protection_plan.main.*.id) : ""
  location            = data.azurerm_resource_group.default.location
}

module "labels" {
  source      = "./../azure-labels"
  name        = var.app_name
  environment = var.environment
  label_order = var.label_order
  extra_tags  = var.tags
}


resource "azurerm_virtual_network" "vnet" {
  count               = var.enabled ? 1 : 0
  name                = format("vn-%s", module.labels.id)
  resource_group_name = local.resource_group_name
  location            = local.location
  address_space       = var.address_space
  dns_servers         = var.dns_servers

  dynamic "ddos_protection_plan" {
    for_each = local.ddos_pp_id != "" ? ["ddos_protection_plan"] : []
    content {
      id     = local.ddos_pp_id
      enable = true
    }
  }
  tags = module.labels.tags
}

resource "azurerm_network_ddos_protection_plan" "main" {
  count               = var.enable_ddos_pp && var.enabled == true ? 1 : 0
  name                = format("ddos-%s", module.labels.id)
  location            = local.location
  resource_group_name = local.resource_group_name
  tags                = module.labels.tags
}

resource "azurerm_subnet" "main" {
  count                                          = var.enable && length(var.subnet_address_prefixes) > 0 ? length(var.subnet_address_prefixes) : 0
  name                                           = var.subnet_name == "" ? format("%s-%s-%d", module.labels.id, "subnet", count.index) : var.subnet_name
  resource_group_name                            = local.resource_group_name
  virtual_network_name                           = join("", azurerm_virtual_network.vnet.*.name)
  address_prefixes                               = [element(var.subnet_address_prefixes, count.index)]
  enforce_private_link_endpoint_network_policies = var.subnet_enforce_private_link_endpoint_network_policies
  enforce_private_link_service_network_policies  = var.subnet_enforce_private_link_service_network_policies

  dynamic "delegation" {
    for_each = var.private_delegation
    content {
      name = lookup(each.value.private_delegation, "name", null)
      service_delegation {
        name    = lookup(each.value.private_delegation.service_delegation, "name", null)
        actions = lookup(each.value.private_delegation.service_delegation, "actions", null)
      }
    }
  }
}

resource "azurerm_route_table" "rt" {
  count               = var.enabled && var.enabled_route_table ? 1 : 0
  name                = format("rt-%s", module.labels.id)
  location            = local.location
  resource_group_name = local.resource_group_name
  dynamic "route" {
    for_each = var.routes
    content {
      name                   = route.value.name
      address_prefix         = route.value.address_prefix
      next_hop_type          = route.value.next_hop_type
      next_hop_in_ip_address = lookup(route.value, "next_hop_in_ip_address", null)
    }
  }
  disable_bgp_route_propagation = var.disable_bgp_route_propagation
  tags                          = module.labels.tags
}

resource "azurerm_subnet_route_table_association" "main" {
  count          = var.enabled && var.enabled_route_table ? length(var.subnet_address_prefixes) : 0
  subnet_id      = element(azurerm_subnet.main.*.id, count.index)
  route_table_id = join("", azurerm_route_table.rt.*.id)
}

resource "azurerm_virtual_network_peering" "peering_vnet" {
  count                        = var.enabled_peering ? length(var.remote_virtual_network_id) : 0
  name                         = format("%s-to-%s", module.labels.id, element(var.remote_virtual_network_name, count.index))
  resource_group_name          = local.resource_group_name
  virtual_network_name         = join("", azurerm_virtual_network.vnet.*.name)
  remote_virtual_network_id    = element(var.remote_virtual_network_id, count.index)
  allow_virtual_network_access = var.allow_virtual_network_access
  allow_forwarded_traffic      = var.allow_forwarded_traffic
  allow_gateway_transit        = var.allow_gateway_transit
  use_remote_gateways          = var.use_remote_gateways

}
