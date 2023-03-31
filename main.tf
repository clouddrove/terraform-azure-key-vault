data "azurerm_client_config" "current_client_config" {}


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
  name                            = format("%s-kv", module.labels.id)
  location                        = var.location
  resource_group_name             = var.resource_group_name
  enabled_for_disk_encryption     = var.enabled_for_disk_encryption
  tenant_id                       = data.azurerm_client_config.current_client_config.tenant_id
  purge_protection_enabled        = var.purge_protection_enabled
  soft_delete_retention_days      = var.soft_delete_retention_days
  enable_rbac_authorization       = var.enable_rbac_authorization
  public_network_access_enabled   = var.public_network_access_enabled
  sku_name                        = var.sku_name
  enabled_for_deployment          = var.enabled_for_deployment
  enabled_for_template_deployment = var.enabled_for_template_deployment
  tags                            = module.labels.tags

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
  dynamic "contact" {
    for_each = var.certificate_contacts
    content {
      email = contact.value.email
      name  = contact.value.name
      phone = contact.value.phone
    }
  }

  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}

resource "azurerm_key_vault_secret" "key_vault_secret" {
  depends_on   = [azurerm_key_vault.key_vault, azurerm_role_assignment.rbac_user_assigned]
  for_each     = var.secrets
  key_vault_id = azurerm_key_vault.key_vault.id
  name         = each.key
  value        = each.value
  tags         = module.labels.tags
}

provider "azurerm" {
  alias = "peer"
  features {}
  subscription_id = var.alias_sub
}

resource "azurerm_private_endpoint" "pep" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = format("%s-pe-kv", module.labels.id)
  location            = var.location
  resource_group_name = var.resource_group_name
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

locals {
  valid_rg_name         = var.existing_private_dns_zone == null ? var.resource_group_name : var.existing_private_dns_zone_resource_group_name
  private_dns_zone_name = var.existing_private_dns_zone == null ? join("", azurerm_private_dns_zone.dnszone.*.name) : var.existing_private_dns_zone
}

data "azurerm_private_endpoint_connection" "private-ip" {
  count               = var.enabled && var.enable_private_endpoint ? 1 : 0
  name                = join("", azurerm_private_endpoint.pep.*.name)
  resource_group_name = var.resource_group_name
  depends_on          = [azurerm_key_vault.key_vault]
}

#data "azurerm_private_dns_zone" "example" {
#  count               = var.enabled && var.enable_private_endpoint ? 1 : 0
#  name                = local.private_dns_zone_name
#  resource_group_name = local.valid_rg_name
#}

resource "azurerm_private_dns_zone" "dnszone" {
  count               = var.enabled && var.existing_private_dns_zone == null && var.enable_private_endpoint ? 1 : 0
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = var.resource_group_name
  tags                = module.labels.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "vent-link" {
  count                 = var.enabled && var.enable_private_endpoint && var.diff_sub == false ? 1 : 0
  name                  = var.existing_private_dns_zone == null ? format("%s-pdz-vnet-link-kv", module.labels.id) : format("%s-pdz-vnet-link-kv-1", module.labels.id)
  resource_group_name   = local.valid_rg_name
  private_dns_zone_name = local.private_dns_zone_name
  virtual_network_id    = var.virtual_network_id
  tags                  = module.labels.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "vent-link-1" {
  provider              = azurerm.peer
  count                 = var.enabled && var.enable_private_endpoint && var.diff_sub == true ? 1 : 0
  name                  = var.existing_private_dns_zone == null ? format("%s-pdz-vnet-link-kv", module.labels.id) : format("%s-pdz-vnet-link-kv-1", module.labels.id)
  resource_group_name   = local.valid_rg_name
  private_dns_zone_name = local.private_dns_zone_name
  virtual_network_id    = var.virtual_network_id
  tags                  = module.labels.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "addon_vent_link" {
  count                 = var.enabled && var.addon_vent_link ? 1 : 0
  name                  = format("%s-pdz-vnet-link-kv-addon", module.labels.id)
  resource_group_name   = var.addon_resource_group_name
  private_dns_zone_name = var.existing_private_dns_zone == null ? join("", azurerm_private_dns_zone.dnszone.*.name) : var.existing_private_dns_zone
  virtual_network_id    = var.addon_virtual_network_id
  tags                  = module.labels.tags
}

resource "azurerm_private_dns_a_record" "arecord" {
  count               = var.enabled && var.enable_private_endpoint && var.diff_sub == false ? 1 : 0
  name                = join("", azurerm_key_vault.key_vault.*.name)
  zone_name           = local.private_dns_zone_name
  resource_group_name = local.valid_rg_name
  ttl                 = 3600
  records             = [data.azurerm_private_endpoint_connection.private-ip.0.private_service_connection.0.private_ip_address]
  tags                = module.labels.tags
  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}

resource "azurerm_private_dns_a_record" "arecord-1" {
  count               = var.enabled && var.enable_private_endpoint && var.diff_sub == true ? 1 : 0
  provider            = azurerm.peer
  name                = join("", azurerm_key_vault.key_vault.*.name)
  zone_name           = local.private_dns_zone_name
  resource_group_name = local.valid_rg_name
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
  resource_group_name = var.resource_group_name
  location            = var.location
  name                = format("midd-keyvault-%s", module.labels.id)
  tags                = module.labels.tags
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
  depends_on   = [azurerm_key_vault.key_vault, ]
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
  tags = module.labels.tags
}

resource "azurerm_monitor_diagnostic_setting" "example" {
  count                          = var.enabled && var.diagnostic_setting_enable ? 1 : 0
  name                           = format("%s-Key-vault-diagnostic-log", module.labels.id)
  target_resource_id             = join("", azurerm_key_vault.key_vault.*.id)
  storage_account_id             = var.storage_account_id
  eventhub_name                  = var.eventhub_name
  eventhub_authorization_rule_id = var.eventhub_authorization_rule_id
  log_analytics_workspace_id     = var.log_analytics_workspace_id
  log_analytics_destination_type = var.log_analytics_destination_type
  metric {
    category = "AllMetrics"
    enabled  = var.Metric_enable
    retention_policy {
      enabled = var.retention_policy_enabled
      days    = var.days
    }
  }
  log {
    category       = var.category
    category_group = "AllLogs"
    retention_policy {
      enabled = var.retention_policy_enabled
      days    = var.days
    }
    enabled = var.log_enabled
  }

  log {
    category       = var.category
    category_group = "Audit"
    retention_policy {
      enabled = var.retention_policy_enabled
      days    = var.days
    }
    enabled = var.log_enabled
  }
  lifecycle {
    ignore_changes = [log_analytics_destination_type]
  }
}

resource "azurerm_monitor_diagnostic_setting" "pe_kv_nic" {
  depends_on                     = [azurerm_private_endpoint.pep]
  count                          = var.enabled && var.diagnostic_setting_enable && var.enable_private_endpoint ? 1 : 0
  name                           = format("%s-pe-kv-nic-diagnostic-log", module.labels.id)
  target_resource_id             = element(azurerm_private_endpoint.pep[count.index].network_interface.*.id, count.index)
  storage_account_id             = var.storage_account_id
  eventhub_name                  = var.eventhub_name
  eventhub_authorization_rule_id = var.eventhub_authorization_rule_id
  log_analytics_workspace_id     = var.log_analytics_workspace_id
  log_analytics_destination_type = var.log_analytics_destination_type
  metric {
    category = "AllMetrics"
    enabled  = var.Metric_enable
    retention_policy {
      enabled = var.retention_policy_enabled
      days    = var.days
    }
  }
  lifecycle {
    ignore_changes = [log_analytics_destination_type]
  }
}
