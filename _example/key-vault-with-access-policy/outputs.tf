output "id" {
  value       = join("", module.vault.*.id)
  description = "The ID of the Key Vault."
}
output "vault_uri" {
  value       = join("", module.vault.*.vault_uri)
  description = "The URI of the Key Vault, used for performing operations on keys and secrets."
}
