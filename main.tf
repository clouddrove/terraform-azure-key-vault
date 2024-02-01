##-----------------------------------------------------------------------------
## Data block to query information 
##-----------------------------------------------------------------------------
data "azurerm_client_config" "current_client_config" {}

##-----------------------------------------------------------------------------
## Locals declaration for determining the local variables
##-----------------------------------------------------------------------------
locals {
  valid_rg_name         = var.existing_private_dns_zone == null ? var.resource_group_name : var.existing_private_dns_zone_resource_group_name
  private_dns_zone_name = var.enable_private_endpoint ? var.existing_private_dns_zone == null ? azurerm_private_dns_zone.dnszone[0].name : var.existing_private_dns_zone : null
}

##-----------------------------------------------------------------------------
## Labels module callled that will be used for naming and tags.
##-----------------------------------------------------------------------------
module "labels" {
  source  = "clouddrove/labels/azure"
  version = "1.0.0"

  name        = var.name
  environment = var.environment
  managedby   = var.managedby
  label_order = var.label_order
  repository  = var.repository
  extra_tags = var.extra_tags
}

##-----------------------------------------------------------------------------
## Below resource will deploy keyvault in your azure environment.
##-----------------------------------------------------------------------------
resource "azurerm_key_vault" "key_vault" {
  count = var.enabled ? 1 : 0

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
    for_each = var.network_acls == null ? [] : [var.network_acls]
    iterator = acl
    content {
      bypass                     = acl.value.bypass
      default_action             = acl.value.default_action
      ip_rules                   = acl.value.ip_rules
      virtual_network_subnet_ids = acl.value.virtual_network_subnet_ids
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

##-----------------------------------------------------------------------------
## Below resource will provide user access on key vault based on policy based in azure environment.
## if rbac is enabled then below resource will create. 
##-----------------------------------------------------------------------------
resource "azurerm_key_vault_access_policy" "readers_policy" {
  for_each = toset(var.enable_rbac_authorization && var.enabled && !var.managed_hardware_security_module_enabled ? [] : var.reader_objects_ids)

  object_id    = each.value
  tenant_id    = data.azurerm_client_config.current_client_config.tenant_id
  key_vault_id = azurerm_key_vault.key_vault[0].id

  key_permissions = [
    "Get",
    "List",
  ]

  secret_permissions = [
    "Get",
    "List",
  ]

  certificate_permissions = [
    "Get",
    "List",
  ]
}

resource "azurerm_key_vault_access_policy" "admin_policy" {
  for_each = toset(var.enable_rbac_authorization && var.enabled && !var.managed_hardware_security_module_enabled ? [] : var.admin_objects_ids)

  object_id    = each.value
  tenant_id    = data.azurerm_client_config.current_client_config.tenant_id
  key_vault_id = azurerm_key_vault.key_vault[0].id

  key_permissions = [
    "Backup",
    "Create",
    "Decrypt",
    "Delete",
    "Encrypt",
    "Get",
    "Import",
    "List",
    "Purge",
    "Recover",
    "Restore",
    "Sign",
    "UnwrapKey",
    "Update",
    "Verify",
    "WrapKey",
    "Rotate",
    "GetRotationPolicy",
    "SetRotationPolicy",
    "Release"
  ]

  secret_permissions = [
    "Backup",
    "Delete",
    "Get",
    "List",
    "Purge",
    "Recover",
    "Restore",
    "Set",
  ]

  certificate_permissions = [
    "Backup",
    "Create",
    "Delete",
    "DeleteIssuers",
    "Get",
    "GetIssuers",
    "Import",
    "List",
    "ListIssuers",
    "ManageContacts",
    "ManageIssuers",
    "Purge",
    "Recover",
    "Restore",
    "SetIssuers",
    "Update",
  ]
}

##-----------------------------------------------------------------------------
## Below resource will provide user access on key vault based on role base access in azure environment.
## if rbac is enabled then below resource will create. 
##-----------------------------------------------------------------------------
resource "azurerm_role_assignment" "rbac_keyvault_administrator" {
  for_each = toset(var.enable_rbac_authorization && var.enabled && !var.managed_hardware_security_module_enabled ? var.admin_objects_ids : [])

  scope                = azurerm_key_vault.key_vault[0].id
  role_definition_name = "Key Vault Administrator"
  principal_id         = each.value
}

resource "azurerm_role_assignment" "rbac_keyvault_secrets_users" {
  for_each = toset(var.enable_rbac_authorization && var.enabled && !var.managed_hardware_security_module_enabled ? var.reader_objects_ids : [])

  scope                = azurerm_key_vault.key_vault[0].id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = each.value
}

resource "azurerm_role_assignment" "rbac_keyvault_reader" {
  for_each = toset(var.enable_rbac_authorization && var.enabled && !var.managed_hardware_security_module_enabled ? var.reader_objects_ids : [])

  scope                = azurerm_key_vault.key_vault[0].id
  role_definition_name = "Key Vault Reader"
  principal_id         = each.value
}

##----------------------------------------------------------------------------- 
## Provider block
## To be used only when there is existing private dns zone in different subscription. Mention other subscription id in 'var.alias_sub'. 
##-----------------------------------------------------------------------------
provider "azurerm" {
  alias = "peer"
  features {}
  subscription_id = var.alias_sub
}

##-----------------------------------------------------------------------------
##Below resource will deploy private endpoint for key vault.
##-----------------------------------------------------------------------------
resource "azurerm_private_endpoint" "pep" {
  count = var.enabled && var.enable_private_endpoint ? 1 : 0

  name                = format("%s-pe-kv", module.labels.id)
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id
  tags                = module.labels.tags
  private_service_connection {
    name                           = format("%s-psc-kv", module.labels.id)
    is_manual_connection           = false
    private_connection_resource_id = azurerm_key_vault.key_vault[0].id
    subresource_names              = ["vault"]
  }
  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}

##----------------------------------------------------------------------------- 
## Data block to retreive private ip of private endpoint.
##-----------------------------------------------------------------------------
data "azurerm_private_endpoint_connection" "private-ip" {
  count = var.enabled && var.enable_private_endpoint ? 1 : 0

  name                = azurerm_private_endpoint.pep[0].name
  resource_group_name = var.resource_group_name
  depends_on          = [azurerm_key_vault.key_vault]
}

##----------------------------------------------------------------------------- 
## Below resource will create private dns zone in your azure subscription. 
## Will be created only when there is no existing private dns zone and private endpoint is enabled. 
##-----------------------------------------------------------------------------
resource "azurerm_private_dns_zone" "dnszone" {
  count = var.enabled && var.existing_private_dns_zone == null && var.enable_private_endpoint ? 1 : 0

  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = var.resource_group_name
  tags                = module.labels.tags
}

##----------------------------------------------------------------------------- 
## Below resource will create vnet link in private dns.
## Vnet link will be created when there is no existing private dns zone or existing private dns zone is in same subscription.  
##-----------------------------------------------------------------------------
resource "azurerm_private_dns_zone_virtual_network_link" "vent-link" {
  count = var.enabled && var.enable_private_endpoint && var.diff_sub == false ? 1 : 0

  name                  = var.existing_private_dns_zone == null ? format("%s-pdz-vnet-link-kv", module.labels.id) : format("%s-pdz-vnet-link-kv-1", module.labels.id)
  resource_group_name   = local.valid_rg_name
  private_dns_zone_name = local.private_dns_zone_name
  virtual_network_id    = var.virtual_network_id
  tags                  = module.labels.tags
}

##----------------------------------------------------------------------------- 
## Below resource will create vnet link in existing private dns zone. 
## Vnet link will be created when existing private dns zone is in different subscription. 
##-----------------------------------------------------------------------------
resource "azurerm_private_dns_zone_virtual_network_link" "vent-link-1" {
  provider = azurerm.peer
  count    = var.enabled && var.enable_private_endpoint && var.diff_sub == true ? 1 : 0

  name                  = var.existing_private_dns_zone == null ? format("%s-pdz-vnet-link-kv", module.labels.id) : format("%s-pdz-vnet-link-kv-1", module.labels.id)
  resource_group_name   = local.valid_rg_name
  private_dns_zone_name = local.private_dns_zone_name
  virtual_network_id    = var.virtual_network_id
  tags                  = module.labels.tags
}

##----------------------------------------------------------------------------- 
## Below resource will create vnet link in existing private dns zone. 
## Vnet link will be created when existing private dns zone is in different subscription. 
## This resource is deployed when more than 1 vnet link is required and module can be called again to do so without deploying other key vault resources. 
##-----------------------------------------------------------------------------
resource "azurerm_private_dns_zone_virtual_network_link" "vent-link-diff-subs" {
  provider = azurerm.peer
  count    = var.enabled && var.multi_sub_vnet_link && var.existing_private_dns_zone != null ? 1 : 0

  name                  = format("%s-pdz-vnet-link-kv-1", module.labels.id)
  resource_group_name   = var.existing_private_dns_zone_resource_group_name
  private_dns_zone_name = var.existing_private_dns_zone
  virtual_network_id    = var.virtual_network_id
  tags                  = module.labels.tags
}

##----------------------------------------------------------------------------- 
## Below resource will create vnet link in private dns zone. 
## Below resource will be created when extra vnet link is required in dns zone in same subscription. 
##-----------------------------------------------------------------------------
resource "azurerm_private_dns_zone_virtual_network_link" "addon_vent_link" {
  count = var.enabled && var.addon_vent_link ? 1 : 0

  name                  = format("%s-pdz-vnet-link-kv-addon", module.labels.id)
  resource_group_name   = var.addon_resource_group_name
  private_dns_zone_name = var.existing_private_dns_zone == null ? azurerm_private_dns_zone.dnszone[0].name : var.existing_private_dns_zone
  virtual_network_id    = var.addon_virtual_network_id
  tags                  = module.labels.tags
}

##----------------------------------------------------------------------------- 
## Below resource will create dns A record for private ip of private endpoint in private dns zone. 
##-----------------------------------------------------------------------------
resource "azurerm_private_dns_a_record" "arecord" {
  count = var.enabled && var.enable_private_endpoint && var.diff_sub == false ? 1 : 0

  name                = azurerm_key_vault.key_vault[0].name
  zone_name           = local.private_dns_zone_name
  resource_group_name = local.valid_rg_name
  ttl                 = 3600
  records             = [data.azurerm_private_endpoint_connection.private-ip[0].private_service_connection[0].private_ip_address]
  tags                = module.labels.tags
  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}

##----------------------------------------------------------------------------- 
## Below resource will create dns A record for private ip of private endpoint in private dns zone. 
## This resource will be created when private dns is in different subscription. 
##-----------------------------------------------------------------------------
resource "azurerm_private_dns_a_record" "arecord-1" {
  count = var.enabled && var.enable_private_endpoint && var.diff_sub == true ? 1 : 0

  provider            = azurerm.peer
  name                = azurerm_key_vault.key_vault[0].name
  zone_name           = local.private_dns_zone_name
  resource_group_name = local.valid_rg_name
  ttl                 = 3600
  records             = [data.azurerm_private_endpoint_connection.private-ip[0].private_service_connection[0].private_ip_address]
  tags                = module.labels.tags
  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}

##----------------------------------------------------------------------------- 
## Below resources will create diagnostic setting for key vault and its components. 
##-----------------------------------------------------------------------------
resource "azurerm_monitor_diagnostic_setting" "example" {
  count = var.enabled && var.diagnostic_setting_enable ? 1 : 0

  name                           = format("%s-Key-vault-diagnostic-log", module.labels.id)
  target_resource_id             = azurerm_key_vault.key_vault[0].id
  storage_account_id             = var.storage_account_id
  eventhub_name                  = var.eventhub_name
  eventhub_authorization_rule_id = var.eventhub_authorization_rule_id
  log_analytics_workspace_id     = var.log_analytics_workspace_id
  log_analytics_destination_type = var.log_analytics_destination_type
  dynamic "metric" {
    for_each = var.metric_enabled ? ["AllMetrics"] : []
    content {
      category = metric.value
      enabled  = true
    }
  }
  dynamic "enabled_log" {
    for_each = var.kv_logs.enabled ? var.kv_logs.category != null ? var.kv_logs.category : var.kv_logs.category_group : []
    content {
      category       = var.kv_logs.category != null ? enabled_log.value : null
      category_group = var.kv_logs.category == null ? enabled_log.value : null
    }
  }
  lifecycle {
    ignore_changes = [log_analytics_destination_type]
  }
}

resource "azurerm_monitor_diagnostic_setting" "pe_kv_nic" {
  depends_on = [azurerm_private_endpoint.pep]
  count      = var.enabled && var.diagnostic_setting_enable && var.enable_private_endpoint ? 1 : 0

  name                           = format("%s-pe-kv-nic-diagnostic-log", module.labels.id)
  target_resource_id             = azurerm_private_endpoint.pep[count.index].network_interface[0].id
  storage_account_id             = var.storage_account_id
  eventhub_name                  = var.eventhub_name
  eventhub_authorization_rule_id = var.eventhub_authorization_rule_id
  log_analytics_workspace_id     = var.log_analytics_workspace_id
  log_analytics_destination_type = var.log_analytics_destination_type
  dynamic "metric" {
    for_each = var.metric_enabled ? ["AllMetrics"] : []
    content {
      category = metric.value
      enabled  = true
    }
  }
  lifecycle {
    ignore_changes = [log_analytics_destination_type]
  }
}

resource "azurerm_key_vault_managed_hardware_security_module" "keyvault_hsm" {
  count = var.enabled && var.managed_hardware_security_module_enabled ? 1 : 0

  name                          = format("%s-hsm-kv", module.labels.id)
  location                      = var.location
  resource_group_name           = var.resource_group_name
  sku_name                      = var.sku_name_hsm
  tenant_id                     = data.azurerm_client_config.current_client_config.tenant_id
  purge_protection_enabled      = var.purge_protection_enabled
  soft_delete_retention_days    = var.soft_delete_retention_days
  admin_object_ids              = var.admin_objects_ids
  public_network_access_enabled = var.public_network_access_enabled

  dynamic "network_acls" {
    for_each = var.network_acls == null ? [] : [var.network_acls]
    iterator = acl
    content {
      bypass         = acl.value.bypass
      default_action = acl.value.default_action
    }
  }

  tags = module.labels.tags
}