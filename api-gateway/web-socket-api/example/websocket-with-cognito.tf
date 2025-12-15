# WebSocket API with Cognito Authorization Example
# This example shows how to set up a WebSocket API with Cognito user pool authentication

provider "aws" {
  region = "us-east-1"
}

locals {
  environment = "production"
  region      = "us-east-1"
  stage_name  = "prod"

  lambda_function_arn  = "arn:aws:lambda:us-east-1:123456789012:function:websocket-handler"
  lambda_function_name = "websocket-handler"

  common_tags = {
    Project     = "websocket-demo"
    ManagedBy   = "terraform"
    Environment = local.environment
  }
}

# ==================== Cognito User Pool ====================
# Create a Cognito User Pool for authentication

resource "aws_cognito_user_pool" "websocket_users" {
  name = "websocket-users-${local.environment}"

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
resource "aws_cognito_user_pool_client" "websocket_client" {
  name         = "websocket-client-${local.environment}"
  user_pool_id = aws_cognito_user_pool.websocket_users.id

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

# ==================== WebSocket API with Cognito ====================

module "websocket_api" {
  source = "../../web-socket-api"

  environment     = local.environment
  region          = local.region
  api_name        = "secure-websocket-api"
  api_description = "WebSocket API with Cognito Authorization"
  stage_name      = local.stage_name

  # Route selection expression
  route_selection_expression = "$request.body.action"

  # Lambda integrations
  connect_lambda_arn    = local.lambda_function_arn
  disconnect_lambda_arn = local.lambda_function_arn
  default_lambda_arn    = local.lambda_function_arn

  # Custom routes
  routes = {
    send_message = {
      route_key  = "sendMessage"
      lambda_arn = local.lambda_function_arn
    }
    broadcast = {
      route_key  = "broadcast"
      lambda_arn = local.lambda_function_arn
    }
  }

  # Enable Cognito Authorization
  enable_cognito_authorizer = true
  cognito_user_pool_arns    = [aws_cognito_user_pool.websocket_users.arn]
  authorizer_name           = "CognitoWebSocketAuth"
  identity_source           = ["route.request.header.Authorization"]

  # Logging and monitoring
  log_retention_in_days = 30
  enable_access_logging = true
  logging_level         = "INFO"
  data_trace_enabled    = false
  throttle_burst_limit  = 5000
  throttle_rate_limit   = 10000

  tags = local.common_tags
}

# ==================== Outputs ====================

output "cognito_user_pool_id" {
  description = "Cognito User Pool ID"
  value       = aws_cognito_user_pool.websocket_users.id
}

output "cognito_user_pool_arn" {
  description = "Cognito User Pool ARN"
  value       = aws_cognito_user_pool.websocket_users.arn
}

output "cognito_client_id" {
  description = "Cognito User Pool Client ID"
  value       = aws_cognito_user_pool_client.websocket_client.id
}

output "websocket_url" {
  description = "WebSocket connection URL (requires Authorization header with JWT token)"
  value       = module.websocket_api.websocket_connection_url
}

output "authorizer_id" {
  description = "WebSocket API Authorizer ID"
  value       = module.websocket_api.authorizer_id
}

# ==================== Usage Instructions ====================

output "connection_instructions" {
  description = "How to connect to the WebSocket with Cognito authentication"
  value = <<-EOT

    To connect to this WebSocket API, you need a valid JWT token from Cognito:

    1. Authenticate with Cognito to get a JWT token:
       - Use AWS Amplify, AWS SDK, or Cognito API
       - You'll receive an ID token or access token

    2. Connect to WebSocket with the token in the Authorization header:

       JavaScript Example:
       ----------------------------------------
       const token = 'YOUR_JWT_TOKEN_HERE';
       const ws = new WebSocket('${module.websocket_api.websocket_connection_url}', {
         headers: {
           'Authorization': token
         }
       });

       ws.onopen = () => {
         console.log('Connected!');
         ws.send(JSON.stringify({ action: 'sendMessage', message: 'Hello' }));
       };

       ws.onmessage = (event) => {
         console.log('Received:', event.data);
       };
       ----------------------------------------

       Python Example (using websockets library):
       ----------------------------------------
       import asyncio
       import websockets
       import json

       async def connect():
           token = 'YOUR_JWT_TOKEN_HERE'
           uri = '${module.websocket_api.websocket_connection_url}'

           async with websockets.connect(
               uri,
               extra_headers={'Authorization': token}
           ) as websocket:
               await websocket.send(json.dumps({
                   'action': 'sendMessage',
                   'message': 'Hello from Python'
               }))

               response = await websocket.recv()
               print(f'Received: {response}')

       asyncio.run(connect())
       ----------------------------------------

    3. Get a JWT token using AWS CLI:
       aws cognito-idp initiate-auth \
         --auth-flow USER_PASSWORD_AUTH \
         --client-id ${aws_cognito_user_pool_client.websocket_client.id} \
         --auth-parameters USERNAME=your-email@example.com,PASSWORD=YourPassword123!

    Cognito Details:
    - User Pool ID: ${aws_cognito_user_pool.websocket_users.id}
    - Client ID: ${aws_cognito_user_pool_client.websocket_client.id}
  EOT
}
