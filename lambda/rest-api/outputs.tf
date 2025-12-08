output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.this.function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.this.arn
}

output "lambda_function_invoke_arn" {
  description = "Invoke ARN of the Lambda function"
  value       = aws_lambda_function.this.invoke_arn
}

output "lambda_function_qualified_arn" {
  description = "Qualified ARN of the Lambda function"
  value       = aws_lambda_function.this.qualified_arn
}

output "lambda_function_version" {
  description = "Latest published version of the Lambda function"
  value       = aws_lambda_function.this.version
}

output "lambda_function_url" {
  description = "URL of the Lambda Function URL"
  value       = var.enable_function_url ? aws_lambda_function_url.this[0].function_url : null
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch Log Group"
  value       = aws_cloudwatch_log_group.lambda.name
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch Log Group"
  value       = aws_cloudwatch_log_group.lambda.arn
}
