output "secret_arn" {
  value       = aws_secretsmanager_secret.this.arn
  description = "The ARN of the secret"
}

output "secret_id" {
  value       = aws_secretsmanager_secret.this.id
  description = "The ID of the secret"
}

output "secret_name" {
  value       = aws_secretsmanager_secret.this.name
  description = "The name of the secret"
}

output "secret_version_id" {
  value       = aws_secretsmanager_secret_version.this.version_id
  description = "The version ID of the current secret"
}

output "secret_string" {
  value       = aws_secretsmanager_secret_version.this.secret_string
  description = "The actual secret values"
  sensitive   = true
}

output "secret_replica" {
  value       = aws_secretsmanager_secret.this.replica
  description = "Attributes of the secret replica, if any"
}
