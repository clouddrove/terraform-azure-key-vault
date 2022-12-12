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

variable "label_order" {
  type        = list(any)
  default     = []
  description = "Label order, e.g. sequence of application name and environment `name`,`environment`,'attribute' [`webserver`,`qa`,`devops`,`public`,] ."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags (e.g. map(`BusinessUnit`,`XYZ`)."
}

variable "managedby" {
  type        = string
  default     = ""
  description = "ManagedBy, eg ''."
}


variable "resource_group_name" {
  default     = ""
  description = "A container that holds related resources for an Azure solution"
}

variable "virtual_network_name" {
  default     = ""
  description = "The name of the virtual network"
}

variable "public_ip_allocation_method" {
  default     = "Static"
  description = "Defines the allocation method for this IP address. Possible values are Static or Dynamic"

}

variable "public_ip_sku" {
  default     = "Standard"
  description = "The SKU of the Public IP. Accepted values are Basic and Standard. Defaults to Basic"
}

variable "azure_bastion_subnet_address_prefix" {
  default     = []
  description = "The address prefix to use for the Azure Bastion subnet"
}

variable "enable_copy_paste" {
  default     = true
  description = "Is Copy/Paste feature enabled for the Bastion Host?"
}

variable "enable_file_copy" {
  default     = false
  description = "Is File Copy feature enabled for the Bastion Host. Only supported whne `sku` is `Standard`"
}

variable "bastion_host_sku" {
  default     = "Basic"
  description = "The SKU of the Bastion Host. Accepted values are `Basic` and `Standard`"
}

variable "enable_ip_connect" {
  default     = false
  description = "Is IP Connect feature enabled for the Bastion Host?"
}

variable "scale_units" {
  default     = 2
  description = "The number of scale units with which to provision the Bastion Host. Possible values are between `2` and `50`. `scale_units` only can be changed when `sku` is `Standard`. `scale_units` is always `2` when `sku` is `Basic`."
}

variable "enable_shareable_link" {
  default     = false
  description = "Is Shareable Link feature enabled for the Bastion Host. Only supported whne `sku` is `Standard`"
}

variable "enable_tunneling" {
  default     = false
  description = "Is Tunneling feature enabled for the Bastion Host. Only supported whne `sku` is `Standard`"
}

variable "enabled" {
  type        = bool
  default     = true
  description = "Set to false to prevent the module from creating any resources."
}
