# Example: Raspberry Pi Device Farm WebSocket API Configuration
#
# This example shows how to configure the WebSocket API Gateway
# for the Raspberry Pi device farm proxy service architecture:
#
# Frontend → WebSocket API Gateway → Lambda (FastAPI) → Pi REST API

provider "aws" {
  region = "us-east-1"
}

locals {
  environment = "production"
  region      = "us-east-1"
  api_name    = "pi-device-farm-websocket"
  stage_name  = "prod"

  # Your Lambda function that runs FastAPI + Mangum
  # This Lambda handles both WebSocket and REST endpoints
  lambda_function_arn = "arn:aws:lambda:us-east-1:123456789012:function:pi-proxy-api"
}

module "websocket_api" {
  source = "../"

  environment     = local.environment
  region          = local.region
  api_name        = local.api_name
  api_description = "WebSocket API for Raspberry Pi Device Farm - Frontend and Device connections"
  stage_name      = local.stage_name

  # Route selection based on request path in your FastAPI app
  # API Gateway will look at the route key to determine which Lambda integration to use
  route_selection_expression = "$request.body.action"

  # Connection lifecycle - All routes point to the same Lambda
  # Your FastAPI app handles the routing internally based on path (/ws vs /ws/device)

  # $connect - Called when any client connects (frontend or device)
  # Your FastAPI WebSocket handler authenticates and registers the connection
  connect_lambda_arn = local.lambda_function_arn

  # $disconnect - Called when client disconnects
  # Your FastAPI handler cleans up connection from WebSocket manager
  disconnect_lambda_arn = local.lambda_function_arn

  # $default - Handles all WebSocket messages
  # Your FastAPI handler processes:
  #   - piCommand actions (calls api_client → Pi REST API)
  #   - sendCommand actions (routes to device WebSocket)
  #   - Device responses (routes back to frontend)
  default_lambda_arn = local.lambda_function_arn

  # Note: We use $default for all messages because your FastAPI app
  # handles action routing internally. If you wanted API Gateway to route
  # based on action, you could define custom routes below.

  # Optional: Custom routes if you want API Gateway to do the routing
  # instead of letting FastAPI handle it via $default
  # routes = {
  #   pi_command = {
  #     route_key  = "piCommand"
  #     lambda_arn = local.lambda_function_arn
  #   }
  #   send_command = {
  #     route_key  = "sendCommand"
  #     lambda_arn = local.lambda_function_arn
  #   }
  # }

  # Logging and monitoring
  log_retention_in_days = 30  # Longer retention for production
  enable_access_logging = true
  logging_level         = "INFO"
  data_trace_enabled    = false  # Set true for debugging

  # Rate limiting - Protect against abuse
  throttle_burst_limit = 5000
  throttle_rate_limit  = 10000

  # Stage variables - Pass to Lambda via context
  stage_variables = {
    # These are accessible in your Lambda event['requestContext']['stage']
    environment = "production"
    version     = "v1"
  }

  tags = {
    Project     = "pi-device-farm"
    ManagedBy   = "terraform"
    Environment = local.environment
    Service     = "websocket-api"
  }
}

# Output the WebSocket URL for your frontend
output "frontend_websocket_url" {
  description = "WebSocket URL for frontend clients to connect to /ws"
  value       = "${module.websocket_api.websocket_connection_url}/ws"
}

output "device_websocket_url" {
  description = "WebSocket URL for Pi devices to connect to /ws/device"
  value       = "${module.websocket_api.websocket_connection_url}/ws/device"
}

output "websocket_api_id" {
  description = "WebSocket API ID for debugging"
  value       = module.websocket_api.websocket_api_id
}

# Example CloudWatch dashboard for monitoring
resource "aws_cloudwatch_dashboard" "websocket_monitoring" {
  dashboard_name = "pi-websocket-api"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ApiGateway", "Count", { stat = "Sum", label = "Total Messages" }],
            [".", "IntegrationLatency", { stat = "Average", label = "Lambda Latency" }],
            [".", "ConnectCount", { stat = "Sum", label = "Connections" }],
          ]
          period = 300
          stat   = "Average"
          region = local.region
          title  = "WebSocket API Metrics"
        }
      }
    ]
  })
}
