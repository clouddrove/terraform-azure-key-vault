## Vritual Network and Subnet Creation
data "azurerm_resource_group" "default" {
  name = var.resource_group_name
}

locals {
  resource_group_name = data.azurerm_resource_group.default.name
  location            = data.azurerm_resource_group.default.location
}

module "labels" {
  source      = "../azure-labels"
  name        = var.app_name
  environment = var.environment
  managedby   = var.managedby
  label_order = var.label_order
  repository  = var.repository
}

resource "azurerm_subnet" "main" {
  count                = var.enabled ? 1 : 0
  name                 = "default"
  resource_group_name  = local.resource_group_name
  virtual_network_name = var.virtual_network_name
  address_prefixes     = var.azure_bastion_subnet_address_prefix
}
resource "azurerm_ssh_public_key" "main" {
  count = var.enabled ? 1 : 0

  name                = format("%s-vm-key", module.labels.id)
  resource_group_name = local.resource_group_name
  location            = local.location
  public_key          = var.public_key == "" ? file(var.key_path) : var.public_key
  tags                = module.labels.tags

}

#---------------------------------------
# Network Interface for Virtual Machine
#---------------------------------------
resource "azurerm_network_interface" "nic" {
  count                         = var.enabled ? 1 : 0
  name                          = format("%s-bastion-nic", module.labels.id)
  resource_group_name           = local.resource_group_name
  location                      = local.location
  dns_servers                   = var.dns_servers
  enable_ip_forwarding          = var.enable_ip_forwarding
  enable_accelerated_networking = var.enable_accelerated_networking
  internal_dns_name_label       = var.internal_dns_name_label
  tags                          = module.labels.tags

  ip_configuration {
    name                          = module.labels.id
    primary                       = true
    subnet_id                     = join("", azurerm_subnet.main.*.id)
    private_ip_address_allocation = var.private_ip_address_allocation_type
    private_ip_address            = var.private_ip_address_allocation_type == "Static" ? element(concat(var.private_ip_address, [""]), count.index) : null
  }

  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}

#---------------------------------------
# Linux Virutal machine
#---------------------------------------
resource "azurerm_linux_virtual_machine" "linux_vm" {
  count                           = var.enabled ? 1 : 0
  name                            = format("%s-bastion-vm", module.labels.id)
  resource_group_name             = local.resource_group_name
  location                        = local.location
  size                            = var.virtual_machine_size
  admin_username                  = var.admin_username
  disable_password_authentication = var.disable_password_authentication
  network_interface_ids           = [join("", azurerm_network_interface.nic.*.id)]
  provision_vm_agent              = true
  allow_extension_operations      = true
  dedicated_host_id               = var.dedicated_host_id
  encryption_at_host_enabled      = var.enable_encryption_at_host
  tags                            = module.labels.tags

  source_image_reference {
    publisher = "Debian"
    offer     = "debian-10"
    sku       = "10"
    version   = "latest"
  }

  dynamic "admin_ssh_key" {
    for_each = var.disable_password_authentication ? [1] : []
    content {
      username   = var.admin_username
      public_key = join("", azurerm_ssh_public_key.main.*.public_key)
    }
  }

  os_disk {
    storage_account_type      = var.os_disk_storage_account_type
    caching                   = var.os_disk_caching
    disk_encryption_set_id    = var.disk_encryption_set_id
    disk_size_gb              = var.disk_size_gb
    write_accelerator_enabled = var.enable_os_disk_write_accelerator
    name                      = format("%s-bastion-ota-disk", module.labels.id)
  }

  additional_capabilities {
    ultra_ssd_enabled = var.enable_ultra_ssd_data_disk_storage_support
  }

  dynamic "identity" {
    for_each = var.managed_identity_type != null ? [1] : []
    content {
      type         = var.managed_identity_type
      identity_ids = var.managed_identity_type == "UserAssigned" || var.managed_identity_type == "SystemAssigned, UserAssigned" ? var.managed_identity_ids : null
    }
  }

  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}
