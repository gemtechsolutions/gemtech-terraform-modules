provider "aws" {
  region = "us-east-1"
}

locals {
  environment       = "test"
  deployment_bucket = "example-lambda-bucket"
  subnet_ids        = []
  security_group_ids = []

  lambda_functions = {
    api_handler = {
      name        = "python-rest-api"
      description = "Python REST API Lambda"
      handler     = "app.handler"
      runtime     = "python3.11"
      s3_key      = "lambda/python-rest-api.zip"
      timeout     = 30
      memory_size = 512
      env_vars = {
        ENVIRONMENT = "test"
        LOG_LEVEL   = "INFO"
      }
    }
  }
}

# IAM role for Lambda execution
resource "aws_iam_role" "lambda_exec_role" {
  for_each = local.lambda_functions

  name = "${each.value.name}-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    environment = local.environment
    Project     = "gemtech-site"
  }
}

# CloudWatch Logs policy for Lambda
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  for_each = local.lambda_functions

  role       = aws_iam_role.lambda_exec_role[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# VPC access policy (only if VPC is enabled)
resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  for_each = length(local.subnet_ids) > 0 ? local.lambda_functions : {}

  role       = aws_iam_role.lambda_exec_role[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

module "lambda" {
  source = "../modules/lambda"

  for_each = local.lambda_functions

  lambda_function_name = each.value.name
  description          = each.value.description
  lambda_exec_role_arn = aws_iam_role.lambda_exec_role[each.key].arn
  environment          = local.environment

  handler        = lookup(each.value, "handler", "app.handler")
  runtime        = lookup(each.value, "runtime", "python3.11")
  lambda_timeout = lookup(each.value, "timeout", 30)
  memory_size    = lookup(each.value, "memory_size", 512)

  s3_bucket = local.deployment_bucket
  s3_key    = each.value.s3_key

  subnet_ids         = local.subnet_ids
  security_group_ids = local.security_group_ids
  enable_vpc         = length(local.subnet_ids) > 0

  lambda_env_vars = lookup(each.value, "env_vars", {})

  log_retention_in_days = 7

  # Enable API Gateway integration
  enable_api_gateway_integration = true
  api_gateway_execution_arn      = aws_api_gateway_rest_api.your_api.execution_arn

  # Enable Lambda Function URL for direct REST API access
  enable_function_url     = false
  function_url_auth_type  = "NONE"
  function_url_cors_config = {
    allow_origins     = ["*"]
    allow_methods     = ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"]
    allow_headers     = ["content-type", "authorization"]
    expose_headers    = ["content-type"]
    max_age           = 86400
    allow_credentials = false
  }

  tags = {
    Project = "gemtech-site"
    Runtime = lookup(each.value, "runtime", "python3.11")
  }
}
