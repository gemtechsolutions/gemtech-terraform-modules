# HTTP API with Cognito Authorization Example

provider "aws" {
  region = "us-east-1"
}

locals {
  environment = "production"
  region      = "us-east-1"
  stage_name  = "prod"

  lambda_function_arn  = "arn:aws:lambda:us-east-1:123456789012:function:http-api-handler"
  lambda_function_name = "http-api-handler"

  common_tags = {
    Project     = "secure-http-api-demo"
    ManagedBy   = "terraform"
    Environment = local.environment
  }
}

# Cognito User Pool
resource "aws_cognito_user_pool" "api_users" {
  name = "http-api-users-${local.environment}"

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }

  auto_verified_attributes = ["email"]

  schema {
    name                = "email"
    attribute_data_type = "String"
    mutable             = true
    required            = true

    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }

  tags = local.common_tags
}

# Cognito User Pool Client
resource "aws_cognito_user_pool_client" "api_client" {
  name         = "http-api-client-${local.environment}"
  user_pool_id = aws_cognito_user_pool.api_users.id

  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH"
  ]

  generate_secret = false
}

module "http_api" {
  source = "../"

  environment     = local.environment
  region          = local.region
  api_name        = "secure-http-api"
  api_description = "HTTP API with Cognito Authorization"
  stage_name      = local.stage_name

  api_resources = {
    api = {
      path_part  = "api"
      lambda_arn = local.lambda_function_arn
      parent_key = null
      methods    = {}
      proxy      = true
    }
  }

  # Enable Cognito Authorization
  enable_cognito_authorizer = true
  cognito_user_pool_id      = aws_cognito_user_pool.api_users.id
  cognito_audience          = [aws_cognito_user_pool_client.api_client.id]
  authorizer_name           = "CognitoHttpAuth"
  identity_source           = ["$request.header.Authorization"]

  log_retention_in_days  = 30
  enable_metrics         = true
  logging_level          = "INFO"
  enable_data_trace      = false
  throttling_burst_limit = 5000
  throttling_rate_limit  = 10000
  enable_cors            = true

  tags = local.common_tags
}

output "cognito_user_pool_id" {
  description = "Cognito User Pool ID"
  value       = aws_cognito_user_pool.api_users.id
}

output "cognito_user_pool_client_id" {
  description = "Cognito User Pool Client ID"
  value       = aws_cognito_user_pool_client.api_client.id
}

output "api_url" {
  description = "HTTP API URL (requires Authorization header with JWT token)"
  value       = module.http_api.http_api_invoke_url
}

output "authorizer_id" {
  description = "API Gateway Authorizer ID"
  value       = module.http_api.authorizer_id
}

output "usage_instructions" {
  description = "How to call the HTTP API with Cognito authentication"
  value = <<-EOT
    Get a JWT token (ID token) from Cognito, then call the API:

    TOKEN="your-id-token"
    curl -H "Authorization: $TOKEN" \\
         ${module.http_api.http_api_invoke_url}/api/hello
  EOT
}
