output "id" {
  value = join("", azurerm_key_vault.key_vault.*.id)
}

output "vault_uri" {
  value = join("", azurerm_key_vault.key_vault.*.vault_uri)
}
