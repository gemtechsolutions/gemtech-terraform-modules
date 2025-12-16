output "http_api_id" {
  description = "ID of the HTTP API Gateway"
  value       = aws_apigatewayv2_api.http.id
}

output "http_api_arn" {
  description = "ARN of the HTTP API Gateway"
  value       = aws_apigatewayv2_api.http.arn
}

output "http_api_execution_arn" {
  description = "Execution ARN of the HTTP API Gateway"
  value       = aws_apigatewayv2_api.http.execution_arn
}

output "http_api_invoke_url" {
  description = "Base invoke URL of the HTTP API Gateway stage"
  value       = aws_apigatewayv2_stage.http.invoke_url
}

output "http_api_stage_name" {
  description = "Name of the HTTP API Gateway stage"
  value       = aws_apigatewayv2_stage.http.name
}

output "http_api_stage_arn" {
  description = "ARN of the HTTP API Gateway stage"
  value       = aws_apigatewayv2_stage.http.arn
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch Log Group for HTTP API"
  value       = aws_cloudwatch_log_group.http_api.name
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch Log Group for HTTP API"
  value       = aws_cloudwatch_log_group.http_api.arn
}

output "authorizer_id" {
  description = "ID of the Cognito authorizer (if enabled)"
  value       = var.enable_cognito_authorizer ? aws_apigatewayv2_authorizer.cognito[0].id : null
}

output "authorizer_enabled" {
  description = "Whether Cognito authorization is enabled"
  value       = var.enable_cognito_authorizer
}
