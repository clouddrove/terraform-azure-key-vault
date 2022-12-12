

output "azure_bastion_service_name" {
  value       = join("", azurerm_bastion_host.main.*.name)
  description = "Specifies the name of the bastion host"
}

output "id" {
  value       = join("", azurerm_bastion_host.main.*.id)
  description = "Specifies the resource id of the bastion host"
}
