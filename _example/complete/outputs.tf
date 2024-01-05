output "id" {
  value       = join("", module.vault.*.id)
  description = "The ID of the Key Vault."
}
output "vault_uri" {
  value = join("", module.vault.*.vault_uri)
}
