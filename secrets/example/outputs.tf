output "secret_arn" {
  value       = module.secrets.secret_arn
  description = "ARN of the stored JSON secret"
}

output "secret_string" {
  value       = module.secrets.secret_string
  description = "JSON-encoded string of secrets"
  sensitive   = true
}