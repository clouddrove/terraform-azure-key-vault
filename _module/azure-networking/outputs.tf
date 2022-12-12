output "subnet_id" {
  value = azurerm_subnet.main.*.id
}
output "vnet_id" {
  value = join("", azurerm_virtual_network.vnet.*.id)
}
output "vnet_name" {
  value = module.labels.id
}
output "name" {
  value = join("", azurerm_virtual_network.vnet.*.name)
}


 