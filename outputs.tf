output "id" {
  value = azurerm_key_vault.key_vault[0].id
}

output "vault_uri" {
  value = azurerm_key_vault.key_vault[0].vault_uri
}
