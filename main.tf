data "azurerm_client_config" "current_client_config" {}

data "azurerm_resource_group" "default" {
  name = var.resource_group_name
}

data "azurerm_subscription" "primary" {
}

locals {
  resource_group_name = data.azurerm_resource_group.default.name
  resource_group_id   = data.azurerm_resource_group.default.id
  location            = data.azurerm_resource_group.default.location
}

module "labels" {

  source  = "clouddrove/labels/azure"
  version = "1.0.0"

  name        = var.name
  environment = var.environment
  managedby   = var.managedby
  label_order = var.label_order
  repository  = var.repository
}

resource "azurerm_key_vault" "key_vault" {
  name                        = format("%s-kv", module.labels.id)
  location                    = local.location
  resource_group_name         = local.resource_group_name
  enabled_for_disk_encryption = var.enabled_for_disk_encryption
  tenant_id                   = data.azurerm_client_config.current_client_config.tenant_id
  purge_protection_enabled    = var.purge_protection_enabled
  soft_delete_retention_days  = var.soft_delete_retention_days
  enable_rbac_authorization   = var.enable_rbac_authorization
  sku_name                    = var.sku_name
  tags                        = module.labels.tags

  dynamic "network_acls" {
    for_each = var.network_acls_bypass == null ? [] : ["acls"]

    content {
      default_action             = var.network_acls_default_action
      bypass                     = var.network_acls_bypass
      ip_rules                   = var.network_acls_ip_rules
      virtual_network_subnet_ids = var.network_acls_subnet_ids
    }
  }
  dynamic "access_policy" {
    for_each = var.access_policy
    content {
      tenant_id               = data.azurerm_client_config.current_client_config.tenant_id
      object_id               = access_policy.value.object_id
      certificate_permissions = access_policy.value.certificate_permissions
      key_permissions         = access_policy.value.key_permissions
      secret_permissions      = access_policy.value.secret_permissions
      storage_permissions     = access_policy.value.storage_permissions
    }
  }
  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}

resource "azurerm_key_vault_secret" "key_vault_secret" {
  for_each     = var.secrets
  key_vault_id = azurerm_key_vault.key_vault.id
  name         = each.key
  value        = each.value
}

resource "azurerm_private_endpoint" "pep" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = format("%s-pe-kv", module.labels.id)
  location            = local.location
  resource_group_name = local.resource_group_name
  subnet_id           = var.subnet_id
  tags                = module.labels.tags
  # private_dns_zone_group {
  #   name                 = format("%s-kv", module.labels.id)
  #   private_dns_zone_ids = var.existing_private_dns_zone == null ? azurerm_private_dns_zone.dnszone.*.id : data.azurerm_private_dns_zone.example.*.id
  # }
  private_service_connection {
    name                           = format("%s-psc-kv", module.labels.id)
    is_manual_connection           = false
    private_connection_resource_id = join("", azurerm_key_vault.key_vault.*.id)
    subresource_names              = ["vault"]
  }

  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}

data "azurerm_private_endpoint_connection" "private-ip" {
  count               = var.enabled && var.enable_private_endpoint ? 1 : 0
  name                = join("", azurerm_private_endpoint.pep.*.name)
  resource_group_name = local.resource_group_name
  depends_on          = [azurerm_key_vault.key_vault]
}

data "azurerm_private_dns_zone" "example" {
  count               = var.enabled && var.enable_private_endpoint ? 1 : 0
  name                = var.existing_private_dns_zone == null ? join("", azurerm_private_dns_zone.dnszone.*.name) : var.existing_private_dns_zone
  resource_group_name = local.resource_group_name
}

resource "azurerm_private_dns_zone" "dnszone" {
  count               = var.enabled && var.existing_private_dns_zone == null && var.enable_private_endpoint ? 1 : 0
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = local.resource_group_name
  tags                = module.labels.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "vent-link" {
  count                 = var.enabled && var.enable_private_endpoint ? 1 : 0
  name                  = format("%s-pdz-vnet-link-kv", module.labels.id)
  resource_group_name   = local.resource_group_name
  private_dns_zone_name = var.existing_private_dns_zone == null ? join("", azurerm_private_dns_zone.dnszone.*.name) : var.existing_private_dns_zone
  virtual_network_id    = var.virtual_network_id
  tags                  = module.labels.tags
}

resource "azurerm_private_dns_a_record" "arecord" {
  count               = var.enabled && var.enable_private_endpoint ? 1 : 0
  name                = join("", azurerm_key_vault.key_vault.*.name)
  zone_name           = var.existing_private_dns_zone == null ? join("", azurerm_private_dns_zone.dnszone.*.name) : var.existing_private_dns_zone
  resource_group_name = local.resource_group_name
  ttl                 = 3600
  records             = [data.azurerm_private_endpoint_connection.private-ip.0.private_service_connection.0.private_ip_address]
  tags                = module.labels.tags
  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}

resource "azurerm_user_assigned_identity" "example" {
  count               = var.enabled ? 1 : 0
  resource_group_name = local.resource_group_name
  location            = local.location
  name                = format("midd-keyvault-%s", module.labels.id)
}


resource "azurerm_role_assignment" "aks_user_assigned" {
  count                = var.enabled ? 1 : 0
  principal_id         = join("", azurerm_user_assigned_identity.example.*.principal_id)
  scope                = join("", azurerm_key_vault.key_vault.*.id)
  role_definition_name = "Reader"
}


resource "azurerm_role_assignment" "rbac_user_assigned" {
  count                = var.enabled && var.enable_rbac_authorization ? length(var.principal_id) : 0
  principal_id         = element(var.principal_id, count.index)
  scope                = join("", azurerm_key_vault.key_vault.*.id)
  role_definition_name = element(var.role_definition_name, count.index)
}

resource "azurerm_key_vault_key" "example" {
  count        = var.enabled ? 1 : 0
  name         = format("mid-keyvault-%s", module.labels.id)
  key_vault_id = join("", azurerm_key_vault.key_vault.*.id)
  key_type     = "RSA"
  key_size     = 2048



  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]
}
