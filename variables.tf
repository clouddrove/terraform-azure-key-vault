#Module      : LABEL
#Description : Terraform label module variables.
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

variable "managedby" {
  type        = string
  default     = ""
  description = "ManagedBy, eg ''."
}

variable "enabled" {
  type        = bool
  description = "Set to false to prevent the module from creating any resources."
  default     = true
}

variable "resource_group_name" {
  type        = string
  default     = ""
  description = "A container that holds related resources for an Azure solution"

}


variable "tags" {
  type        = map(string)
  default     = {}
  description = "A map of tags to add to all resources"
}

variable "sku_name" {
  type        = string
  default     = "standard"
  description = "The Name of the SKU used for this Key Vault. Possible values are standard and premium"
}

variable "enabled_for_disk_encryption" {
  type        = bool
  default     = null
  description = "Boolean flag to specify whether Azure Disk Encryption is permitted to retrieve secrets from the vault and unwrap keys. Defaults to false"
}

variable "purge_protection_enabled" {
  type        = bool
  default     = null
  description = "Is Purge Protection enabled for this Key Vault? Defaults to false"
}

variable "network_acls_default_action" {
  type        = string
  default     = "Deny"
  description = "The Default Action to use when no rules match from ip_rules / virtual_network_subnet_ids. Possible values are Allow and Deny."
}

variable "network_acls_bypass" {
  type        = string
  default     = null
  description = "Specifies which traffic can bypass the network rules. Possible values are AzureServices and None."
}

variable "network_acls_ip_rules" {
  default     = null
  type        = list(string)
  description = "(Optional) One or more IP Addresses, or CIDR Blocks which should be able to access the Key Vault."
}

variable "network_acls_subnet_ids" {
  default     = null
  type        = list(string)
  description = "(Optional) One or more Subnet ID's which should be able to access this Key Vault."
}

variable "secrets" {
  default     = {}
  description = "List of secrets for be created"
}

variable "soft_delete_retention_days" {
  type        = number
  default     = 90
  description = "The number of days that items should be retained for once soft-deleted. The valid value can be between 7 and 90 days"

}
variable "access_policies" {
  type = list(object({
    object_id               = string,
    certificate_permissions = list(string),
    key_permissions         = list(string),
    secret_permissions      = list(string),
    storage_permissions     = list(string),
  }))
  default     = []
  description = "Map of access policies for an object_id (user, service principal, security group) to backend."
}

variable "access_policy" {
  type = list(object({
    object_id               = string,
    certificate_permissions = list(string),
    key_permissions         = list(string),
    secret_permissions      = list(string),
    storage_permissions     = list(string),
  }))
  default     = []
  description = "Map of access policies for an object_id (user, service principal, security group) to backend."
}



variable "enable_private_endpoint" {
  type        = bool
  default     = true
  description = "Manages a Private Endpoint to Azure database for MySQL"
}

variable "virtual_network_name" {
  type        = string
  default     = ""
  description = "The name of the virtual network"
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
