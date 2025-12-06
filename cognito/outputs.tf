output "user_pool_id" {
  value = aws_cognito_user_pool.this.id
}

output "user_pool_arn" {
  value = aws_cognito_user_pool.this.arn
}

output "client_ids" {
  value = {
    for c in aws_cognito_user_pool_client.clients : c.name => c.id
  }
}
