# REST API with Cognito Authorization Example
# This example shows how to set up a REST API with Cognito user pool authentication

provider "aws" {
  region = "us-east-1"
}

locals {
  environment = "production"
  region      = "us-east-1"
  stage_name  = "prod"

  lambda_function_arn  = "arn:aws:lambda:us-east-1:123456789012:function:api-handler"
  lambda_function_name = "api-handler"

  common_tags = {
    Project     = "secure-api-demo"
    ManagedBy   = "terraform"
    Environment = local.environment
  }
}

# ==================== Cognito User Pool ====================

resource "aws_cognito_user_pool" "api_users" {
  name = "api-users-${local.environment}"

  # Password policy
  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }

  # Auto-verified attributes
  auto_verified_attributes = ["email"]

  # User attributes
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
  name         = "api-client-${local.environment}"
  user_pool_id = aws_cognito_user_pool.api_users.id

  # OAuth settings
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH"
  ]

  # Token validity
  id_token_validity      = 60  # minutes
  access_token_validity  = 60  # minutes
  refresh_token_validity = 30  # days

  token_validity_units {
    id_token      = "minutes"
    access_token  = "minutes"
    refresh_token = "days"
  }

  prevent_user_existence_errors = "ENABLED"
  generate_secret              = false
}

# ==================== REST API with Cognito ====================

module "rest_api" {
  source = "../"

  environment     = local.environment
  region          = local.region
  api_name        = "secure-rest-api"
  api_description = "REST API with Cognito Authorization"
  stage_name      = local.stage_name
  endpoint_type   = "REGIONAL"

  # API Resources with proxy integration
  api_resources = {
    api = {
      path_part  = "api"
      lambda_arn = local.lambda_function_arn
      parent_key = null
      methods    = {}
      proxy      = true # Proxy all requests under /api/* to Lambda
    }
  }

  # Enable Cognito Authorization
  enable_cognito_authorizer        = true
  cognito_user_pool_arns           = [aws_cognito_user_pool.api_users.arn]
  authorizer_name                  = "CognitoApiAuth"
  identity_source                  = "method.request.header.Authorization"
  authorizer_result_ttl_in_seconds = 300 # Cache authorizer results for 5 minutes

  # Logging and monitoring
  log_retention_in_days  = 30
  enable_xray_tracing    = true
  enable_metrics         = true
  logging_level          = "INFO"
  enable_data_trace      = false
  throttling_burst_limit = 5000
  throttling_rate_limit  = 10000
  enable_cors            = true

  tags = local.common_tags
}

# ==================== Outputs ====================

output "cognito_user_pool_id" {
  description = "Cognito User Pool ID"
  value       = aws_cognito_user_pool.api_users.id
}

output "cognito_user_pool_arn" {
  description = "Cognito User Pool ARN"
  value       = aws_cognito_user_pool.api_users.arn
}

output "cognito_client_id" {
  description = "Cognito User Pool Client ID"
  value       = aws_cognito_user_pool_client.api_client.id
}

output "api_url" {
  description = "REST API URL (requires Authorization header with JWT token)"
  value       = module.rest_api.api_gateway_url
}

output "authorizer_id" {
  description = "API Gateway Authorizer ID"
  value       = module.rest_api.authorizer_id
}

# ==================== Usage Instructions ====================

output "usage_instructions" {
  description = "How to call the REST API with Cognito authentication"
  value = <<-EOT

    To call this REST API, you need a valid JWT token from Cognito:

    1. Authenticate with Cognito to get a JWT token:

       Using AWS CLI:
       ----------------------------------------
       aws cognito-idp initiate-auth \
         --auth-flow USER_PASSWORD_AUTH \
         --client-id ${aws_cognito_user_pool_client.api_client.id} \
         --auth-parameters USERNAME=your-email@example.com,PASSWORD=YourPassword123!

       This returns an IdToken which you'll use in the Authorization header.
       ----------------------------------------

    2. Call the API with the token:

       Using curl:
       ----------------------------------------
       TOKEN="your-id-token-here"
       curl -H "Authorization: $TOKEN" \
            ${module.rest_api.api_gateway_url}/api/your-endpoint
       ----------------------------------------

       Using JavaScript (fetch):
       ----------------------------------------
       const token = 'your-id-token-here';

       fetch('${module.rest_api.api_gateway_url}/api/your-endpoint', {
         method: 'GET',
         headers: {
           'Authorization': token,
           'Content-Type': 'application/json'
         }
       })
       .then(response => response.json())
       .then(data => console.log(data))
       .catch(error => console.error('Error:', error));
       ----------------------------------------

       Using Python (requests):
       ----------------------------------------
       import requests

       token = 'your-id-token-here'
       url = '${module.rest_api.api_gateway_url}/api/your-endpoint'

       headers = {
           'Authorization': token,
           'Content-Type': 'application/json'
       }

       response = requests.get(url, headers=headers)
       print(response.json())
       ----------------------------------------

    3. Create a test user:

       Using AWS CLI:
       ----------------------------------------
       # Create user
       aws cognito-idp admin-create-user \
         --user-pool-id ${aws_cognito_user_pool.api_users.id} \
         --username test@example.com \
         --user-attributes Name=email,Value=test@example.com \
         --temporary-password TempPassword123!

       # Set permanent password
       aws cognito-idp admin-set-user-password \
         --user-pool-id ${aws_cognito_user_pool.api_users.id} \
         --username test@example.com \
         --password YourPassword123! \
         --permanent
       ----------------------------------------

    Cognito Details:
    - User Pool ID: ${aws_cognito_user_pool.api_users.id}
    - Client ID: ${aws_cognito_user_pool_client.api_client.id}
    - API URL: ${module.rest_api.api_gateway_url}

    Note: Without a valid JWT token in the Authorization header, all requests
    will be rejected with a 401 Unauthorized response.
  EOT
}
