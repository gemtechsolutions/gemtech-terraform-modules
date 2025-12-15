# Complete Raspberry Pi Device Farm Architecture
# Two API Gateways → One Lambda → Pi REST API

provider "aws" {
  region = "us-east-1"
}

locals {
  environment = "production"
  region      = "us-east-1"
  stage_name  = "prod"

  # Single Lambda function that handles both HTTP and WebSocket
  lambda_function_arn  = "arn:aws:lambda:us-east-1:123456789012:function:pi-proxy-api"
  lambda_function_name = "pi-proxy-api"

  common_tags = {
    Project     = "pi-device-farm"
    ManagedBy   = "terraform"
    Environment = local.environment
  }
}

# ==================== REST API Gateway ====================
# Handles HTTP requests to /api/* endpoints

module "rest_api" {
  source = "../../rest-api"

  environment     = local.environment
  region          = local.region
  api_name        = "pi-device-farm-rest-api"
  api_description = "REST API for Raspberry Pi Device Farm - HTTP endpoints"
  stage_name      = local.stage_name
  endpoint_type   = "REGIONAL"

  # Define all your REST API resources
  # Your FastAPI app has 8 routers with 66 endpoints
  api_resources = {
    # Root API path
    api = {
      path_part  = "api"
      lambda_arn = local.lambda_function_arn
      parent_key = null
      methods    = {}
      proxy      = true # Enable proxy for all paths under /api/*
    }
  }

  # Optional: Enable Cognito authorization
  # Uncomment and configure the following to enable Cognito authorizer
  # enable_cognito_authorizer = true
  # cognito_user_pool_arns    = ["arn:aws:cognito-idp:us-east-1:123456789012:userpool/us-east-1_XXXXXXXXX"]
  # authorizer_name           = "RestApiCognitoAuth"
  # identity_source           = "method.request.header.Authorization"
  # authorizer_result_ttl_in_seconds = 300

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

# ==================== WebSocket API Gateway ====================
# Handles WebSocket connections for /ws and /ws/device

module "websocket_api" {
  source = "../../web-socket-api"

  environment     = local.environment
  region          = local.region
  api_name        = "pi-device-farm-websocket-api"
  api_description = "WebSocket API for Raspberry Pi Device Farm - Real-time connections"
  stage_name      = local.stage_name

  # Route selection expression
  # API Gateway will use the "action" field from message body
  route_selection_expression = "$request.body.action"

  # All routes point to the same Lambda
  # Your FastAPI app routes internally based on path and action
  connect_lambda_arn    = local.lambda_function_arn
  disconnect_lambda_arn = local.lambda_function_arn
  default_lambda_arn    = local.lambda_function_arn

  # Optional: Define custom routes for specific actions
  # This allows API Gateway to route messages instead of using $default
  routes = {
    pi_command = {
      route_key  = "piCommand"
      lambda_arn = local.lambda_function_arn
    }
    send_command = {
      route_key  = "sendCommand"
      lambda_arn = local.lambda_function_arn
    }
  }

  # Optional: Enable Cognito authorization
  # Uncomment and configure the following to enable Cognito authorizer
  # enable_cognito_authorizer = true
  # cognito_user_pool_arns    = ["arn:aws:cognito-idp:us-east-1:123456789012:userpool/us-east-1_XXXXXXXXX"]
  # authorizer_name           = "WebSocketCognitoAuth"
  # identity_source           = ["route.request.header.Authorization"]

  # Logging and monitoring
  log_retention_in_days = 30
  enable_access_logging = true
  logging_level         = "INFO"
  data_trace_enabled    = false
  throttle_burst_limit  = 5000
  throttle_rate_limit   = 10000

  tags = local.common_tags
}

# ==================== Lambda Permissions ====================
# These are automatically created by the modules, but shown here for clarity

# REST API Gateway needs permission to invoke Lambda
# (Created by rest-api module via aws_lambda_permission.apigw_proxy)

# WebSocket API Gateway needs permission to invoke Lambda
# (Created by websocket-api module via aws_lambda_permission resources)

# ==================== Outputs ====================

output "rest_api_url" {
  description = "Base URL for REST API (use for HTTP requests)"
  value       = module.rest_api.api_gateway_url
}

output "rest_api_endpoints" {
  description = "Example REST API endpoints"
  value = {
    devices    = "${module.rest_api.api_gateway_url}/api/devices"
    wifi       = "${module.rest_api.api_gateway_url}/api/wifi"
    accounts   = "${module.rest_api.api_gateway_url}/api/accounts"
    tasks      = "${module.rest_api.api_gateway_url}/api/tasks"
    health     = "${module.rest_api.api_gateway_url}/health"
  }
}

output "websocket_url" {
  description = "WebSocket connection URL"
  value       = module.websocket_api.websocket_connection_url
}

output "websocket_endpoints" {
  description = "WebSocket endpoints for different connection types"
  value = {
    frontend = "${module.websocket_api.websocket_connection_url}"
    # Note: Path routing (/ws vs /ws/device) happens in your FastAPI app
    # API Gateway just establishes the WebSocket connection
    frontend_path = "wss://${replace(module.websocket_api.websocket_api_endpoint, "wss://", "")}/${local.stage_name}"
  }
}

output "architecture_summary" {
  description = "Summary of the deployed architecture"
  value = {
    rest_api_gateway     = module.rest_api.api_gateway_id
    websocket_api_gateway = module.websocket_api.websocket_api_id
    lambda_function      = local.lambda_function_name
    pattern              = "Two API Gateways → One Lambda → Pi REST API"
  }
}

# ==================== Usage Examples ====================

output "usage_examples" {
  description = "How to use the deployed APIs"
  value = {
    rest_curl = "curl ${module.rest_api.api_gateway_url}/api/devices"
    websocket_js = <<-EOT
      // JavaScript WebSocket connection
      const ws = new WebSocket('${module.websocket_api.websocket_connection_url}');

      ws.onopen = () => {
        // Send piCommand to execute Pi API operation
        ws.send(JSON.stringify({
          action: 'piCommand',
          category: 'devices',
          operation: 'list_devices'
        }));
      };

      ws.onmessage = (event) => {
        const response = JSON.parse(event.data);
        console.log('Response:', response);
      };
    EOT
  }
}
