#Module      : LABEL
#Description : Terraform label module variables.
variable "app_name" {
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
  default     = ""
  description = "A container that holds related resources for an Azure solution"
}

# nic
variable "dns_servers" {
  default     = []
  description = "List of dns servers to use for network interface"

}

variable "enable_ip_forwarding" {
  type        = bool
  default     = false
  description = "Should IP Forwarding be enabled? Defaults to false"
}

variable "enable_accelerated_networking" {
  type        = bool
  default     = false
  description = "Should Accelerated Networking be enabled? Defaults to false."

}

variable "internal_dns_name_label" {
  default     = null
  description = "The (relative) DNS Name used for internal communications between Virtual Machines in the same Virtual Network."

}
variable "subnet_id" {

}

variable "private_ip_address_allocation_type" {
  default     = "Dynamic"
  description = "The allocation method used for the Private IP Address. Possible values are Dynamic and Static."
}

variable "private_ip_address" {
  default     = null
  description = "The Static IP Address which should be used. This is valid only when `private_ip_address_allocation` is set to `Static` "
}

#vm

variable "virtual_machine_size" {
  default     = "Standard_A2_v2"
  description = "The Virtual Machine SKU for the Virtual Machine, Default is Standard_A2_V2"
}

variable "disable_password_authentication" {
  type        = bool
  default     = true
  description = "Should Password Authentication be disabled on this Virtual Machine? Defaults to true."
}

variable "admin_username" {
  default     = "azureadmin"
  description = "The username of the local administrator used for the Virtual Machine."
}

variable "source_image_id" {
  default     = null
  description = "The ID of an Image which each Virtual Machine should be based on"
}

variable "dedicated_host_id" {
  default     = null
  description = "The ID of a Dedicated Host where this machine should be run on."
}

variable "enable_encryption_at_host" {
  default     = false
  description = "Should all of the disks (including the temp disk) attached to this Virtual Machine be encrypted by enabling Encryption at Host?"

}

variable "os_disk_storage_account_type" {
  default     = "StandardSSD_LRS"
  description = "The Type of Storage Account which should back this the Internal OS Disk. Possible values include Standard_LRS, StandardSSD_LRS and Premium_LRS."
}

variable "os_disk_caching" {
  default     = "ReadWrite"
  description = "The Type of Caching which should be used for the Internal OS Disk. Possible values are `None`, `ReadOnly` and `ReadWrite`"
}

variable "disk_encryption_set_id" {
  default     = null
  description = "The ID of the Disk Encryption Set which should be used to Encrypt this OS Disk. The Disk Encryption Set must have the `Reader` Role Assignment scoped on the Key Vault - in addition to an Access Policy to the Key Vault"
}

variable "disk_size_gb" {
  default     = null
  description = "The Size of the Internal OS Disk in GB, if you wish to vary from the size used in the image this Virtual Machine is sourced from."
}

variable "enable_os_disk_write_accelerator" {
  default     = false
  description = "Should Write Accelerator be Enabled for this OS Disk? This requires that the `storage_account_type` is set to `Premium_LRS` and that `caching` is set to `None`."
}

variable "enable_ultra_ssd_data_disk_storage_support" {
  default     = false
  description = "Should the capacity to enable Data Disks of the UltraSSD_LRS storage account type be supported on this Virtual Machine"
}

variable "managed_identity_type" {
  default     = null
  description = "The type of Managed Identity which should be assigned to the Linux Virtual Machine. Possible values are `SystemAssigned`, `UserAssigned` and `SystemAssigned, UserAssigned`"
}

variable "managed_identity_ids" {
  default     = null
  description = "A list of User Managed Identity ID's which should be assigned to the Linux Virtual Machine."
}

#key_pair
variable "public_key" {
  type        = string
  default     = ""
  description = "Name  (e.g. `ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD3F6tyPEFEzV0LX3X8BsXdMsQ`)."
  sensitive   = true
}

variable "key_path" {
  type        = string
  default     = ""
  description = "Name  (e.g. `~/.ssh/id_rsa.pub`)."
}

variable "virtual_network_name" {
  default     = ""
  description = "The name of the virtual network"
}

variable "azure_bastion_subnet_address_prefix" {
  default     = []
  description = "The address prefix to use for the Azure Bastion subnet"
}

