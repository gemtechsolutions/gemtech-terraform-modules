output "http_api_id" {
  description = "ID of the HTTP API Gateway"
  value       = module.http_api.http_api_id
}

output "http_api_arn" {
  description = "ARN of the HTTP API Gateway"
  value       = module.http_api.http_api_arn
}

output "http_api_execution_arn" {
  description = "Execution ARN for Lambda permissions"
  value       = module.http_api.http_api_execution_arn
}

output "http_api_invoke_url" {
  description = "Base URL of the HTTP API Gateway"
  value       = module.http_api.http_api_invoke_url
}

output "http_api_stage_name" {
  description = "HTTP API Gateway stage name"
  value       = module.http_api.http_api_stage_name
}

output "cloudwatch_log_group_name" {
  description = "CloudWatch Log Group name for HTTP API"
  value       = module.http_api.cloudwatch_log_group_name
}

output "api_endpoints" {
  description = "Full API endpoint URLs"
  value = {
    for key, resource in local.api_resources :
    key => "${module.http_api.http_api_invoke_url}/${key}"
  }
}

output "example_curl_commands" {
  description = "Example curl commands to test the API"
  value = {
    for key, resource in local.api_resources :
    key => "curl ${module.http_api.http_api_invoke_url}/${key}"
  }
}
