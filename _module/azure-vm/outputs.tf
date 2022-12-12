output "nic_name" {
  value = azurerm_network_interface.nic.*.name
}

output "virtual_machine_name" {
  value = azurerm_linux_virtual_machine.linux_vm.*.name
}

