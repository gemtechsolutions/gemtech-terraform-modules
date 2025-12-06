output "dynamodb_table_arn" {
  value       = aws_dynamodb_table.this.arn
  description = "The ARN of the DynamoDB table"
}

output "dynamodb_table_id" {
  value       = aws_dynamodb_table.this.id
  description = "The name of the DynamoDB table"
}
