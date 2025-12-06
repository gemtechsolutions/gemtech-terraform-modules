output "dynamodb_table_arns" {
  description = "ARNs of the DynamoDB tables"
  value = {
    for k, v in module.dynamodb_table :
    k => v.dynamodb_table_arn
  }
}

output "dynamodb_table_ids" {
  description = "IDs (names) of the DynamoDB tables"
  value = {
    for k, v in module.dynamodb_table :
    k => v.dynamodb_table_id
  }
}
