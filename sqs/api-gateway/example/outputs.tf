output "api_gateway_id" {
  description = "ID of the API Gateway"
  value       = module.api_gateway.api_gateway_id
}

output "api_gateway_arn" {
  description = "ARN of the API Gateway"
  value       = module.api_gateway.api_gateway_arn
}

output "api_gateway_execution_arn" {
  description = "Execution ARN for Lambda permissions"
  value       = module.api_gateway.api_gateway_execution_arn
}

output "api_gateway_url" {
  description = "Base URL of the API Gateway"
  value       = module.api_gateway.api_gateway_url
}

output "api_gateway_stage_name" {
  description = "API Gateway stage name"
  value       = module.api_gateway.api_gateway_stage_name
}

output "cloudwatch_log_group_name" {
  description = "CloudWatch Log Group name for API Gateway"
  value       = module.api_gateway.cloudwatch_log_group_name
}

output "api_endpoints" {
  description = "Full API endpoint URLs"
  value = {
    for key, resource in local.api_resources :
    key => "${module.api_gateway.api_gateway_url}/${key}"
  }
}

output "example_curl_commands" {
  description = "Example curl commands to test the API"
  value = {
    for key, resource in local.api_resources :
    key => "curl ${module.api_gateway.api_gateway_url}/${key}"
  }
}
