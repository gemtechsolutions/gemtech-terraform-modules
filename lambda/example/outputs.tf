output "lambda_functions" {
  description = "Map of Lambda function details"
  value = {
    for k, v in module.lambda :
    k => {
      name        = v.lambda_function_name
      arn         = v.lambda_function_arn
      invoke_arn  = v.lambda_function_invoke_arn
      version     = v.lambda_function_version
      url         = v.lambda_function_url
      log_group   = v.cloudwatch_log_group_name
    }
  }
}

output "api_endpoints" {
  description = "Lambda Function URLs for REST API access"
  value = {
    for k, v in module.lambda :
    k => v.lambda_function_url
  }
}
