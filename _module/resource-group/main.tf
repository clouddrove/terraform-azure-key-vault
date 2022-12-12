

module "labels" {
  source      = "./../azure-labels"
  name        = var.app_name
  environment = var.environment
  label_order = var.label_order
  attributes  = var.attributes
  extra_tags  = var.tags
}


resource "azurerm_resource_group" "default" {
  count    = var.enabled ? 1 : 0
  name     = format("rg-%s", module.labels.id)
  location = var.location
  tags     = module.labels.tags

  timeouts {
    create = var.create
    read   = var.read
    update = var.update
    delete = var.delete
  }
}
