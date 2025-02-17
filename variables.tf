
variable "name" {
  type        = string
  default     = ""
  description = "Name  (e.g. `app` or `cluster`)."
}

variable "environment" {
  type        = string
  default     = ""
  description = "Environment (e.g. `prod`, `dev`, `staging`)."
}

variable "repository" {
  type        = string
  default     = ""
  description = "Terraform current module repo"
}

variable "label_order" {
  type        = list(any)
  default     = []
  description = "Label order, e.g. sequence of application name and environment `name`,`environment`,'attribute' [`webserver`,`qa`,`devops`,`public`,] ."
}

variable "secrets" {
  type        = map(string)
  description = "Map of secrets to be stored in the Key Vault"
  default     = {}
}


variable "managedby" {
  type        = string
  default     = ""
  description = "ManagedBy, eg ''."
}

variable "extra_tags" {
  type        = map(string)
  default     = null
  description = "Variable to pass extra tags."
}

variable "enabled" {
  type        = bool
  default     = true
  description = "Set to false to prevent the module from creating any resources."
}

variable "resource_group_name" {
  type        = string
  default     = ""
  description = "A container that holds related resources for an Azure solution"

}

variable "location" {
  type        = string
  default     = null
  description = "Location where resource group will be created."
}

variable "sku_name" {
  type        = string
  default     = "standard"
  description = "The Name of the SKU used for this Key Vault. Possible values are standard and premium"
}

variable "enabled_for_disk_encryption" {
  type        = bool
  default     = true
  description = "Boolean flag to specify whether Azure Disk Encryption is permitted to retrieve secrets from the vault and unwrap keys. Defaults to false"
}

variable "purge_protection_enabled" {
  type        = bool
  default     = true
  description = "Is Purge Protection enabled for this Key Vault? Defaults to false"
}


variable "soft_delete_retention_days" {
  type        = number
  default     = 90
  description = "The number of days that items should be retained for once soft-deleted. The valid value can be between 7 and 90 days"

}
variable "enabled_for_deployment" {
  type        = bool
  default     = false
  description = "Boolean flag to specify whether Azure Virtual Machines are permitted to retrieve certificates stored as secrets from the key vault."
}
variable "enabled_for_template_deployment" {
  type        = bool
  default     = false
  description = " Boolean flag to specify whether Azure Resource Manager is permitted to retrieve secrets from the key vault."
}
variable "certificate_contacts" {
  type = list(object({
    email = string
    name  = optional(string)
    phone = optional(string)
  }))
  default     = []
  description = "Contact information to send notifications triggered by certificate lifetime events"
}

variable "admin_objects_ids" {
  description = "IDs of the objects that can do all operations on all keys, secrets and certificates."
  type        = list(string)
  default     = []
}

variable "reader_objects_ids" {
  description = "IDs of the objects that can read all keys, secrets and certificates."
  type        = list(string)
  default     = []
}

variable "enable_private_endpoint" {
  type        = bool
  default     = true
  description = "Manages a Private Endpoint to Azure database for MySQL"
}


variable "virtual_network_id" {
  type        = string
  default     = ""
  description = "The name of the virtual network"
}

variable "subnet_id" {
  type        = string
  default     = ""
  description = "The resource ID of the subnet"
}

variable "existing_private_dns_zone" {
  type        = string
  default     = null
  description = "Name of the existing private DNS zone"
}

variable "enable_rbac_authorization" {
  type        = bool
  default     = true
  description = "(Optional) Boolean flag to specify whether Azure Key Vault uses Role Based Access Control (RBAC) for authorization of data actions."
}

variable "existing_private_dns_zone_resource_group_name" {
  type        = string
  default     = ""
  description = "The name of the existing resource group"
}

variable "public_network_access_enabled" {
  type        = bool
  default     = true
  description = "(Optional) Whether public network access is allowed for this Key Vault. Defaults to true"
}

## Addon vritual link
variable "addon_vent_link" {
  type        = bool
  default     = false
  description = "The name of the addon vnet "
}

variable "addon_resource_group_name" {
  type        = string
  default     = ""
  description = "The name of the addon vnet resource group"
}

variable "addon_virtual_network_id" {
  type        = string
  default     = ""
  description = "The name of the addon vnet link vnet id"
}

variable "log_analytics_destination_type" {
  type        = string
  default     = "AzureDiagnostics"
  description = "Possible values are AzureDiagnostics and Dedicated, default to AzureDiagnostics. When set to Dedicated, logs sent to a Log Analytics workspace will go into resource specific tables, instead of the legacy AzureDiagnostics table."
}

variable "metric_enabled" {
  type        = bool
  default     = true
  description = "Is this Diagnostic Metric enabled? Defaults to true."
}

variable "kv_logs" {
  type = object({
    enabled        = bool
    category       = optional(list(string))
    category_group = optional(list(string))
  })

  default = {
    enabled        = true
    category_group = ["AllLogs"]
  }
}

variable "diagnostic_setting_enable" {
  type    = bool
  default = false
}
variable "log_analytics_workspace_id" {
  type    = string
  default = null
}

variable "storage_account_id" {
  type        = string
  default     = null
  description = "The ID of the Storage Account where logs should be sent."
}
variable "eventhub_name" {
  type        = string
  default     = null
  description = "Specifies the name of the Event Hub where Diagnostics Data should be sent."
}
variable "eventhub_authorization_rule_id" {
  type        = string
  default     = null
  description = "Specifies the ID of an Event Hub Namespace Authorization Rule used to send Diagnostics Data."
}

variable "diff_sub" {
  # To be set true when hosted DNS zone is in different subnscription.
  type        = bool
  default     = false
  description = "Flag to tell whether dns zone is in different sub or not."
}

variable "multi_sub_vnet_link" {
  type        = bool
  default     = false
  description = "Flag to control creation of vnet link for dns zone in different subscription"
}

variable "managed_hardware_security_module_enabled" {
  description = "Create a KeyVault Managed HSM resource if enabled. Changing this forces a new resource to be created."
  type        = bool
  default     = false
}

variable "sku_name_hsm" {
  type        = string
  default     = "Standard_B1"
  description = "The Name of the SKU used for this Key Vault hsm."
}

variable "network_acls" {
  description = "Object with attributes: `bypass`, `default_action`, `ip_rules`, `virtual_network_subnet_ids`. Set to `null` to disable. See https://www.terraform.io/docs/providers/azurerm/r/key_vault.html#bypass for more information."
  type = object({
    bypass                     = optional(string, "None"),
    default_action             = optional(string, "Deny"),
    ip_rules                   = optional(list(string)),
    virtual_network_subnet_ids = optional(list(string)),
  })
  default = {}
}
