output "id" {
  value       = module.vault[0].id
  description = "The ID of the Key Vault."
}
output "vault_uri" {
  value = module.vault[0].vault_uri
}
