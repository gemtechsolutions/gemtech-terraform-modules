provider "aws" {
  region = "us-east-1"
}

locals {
  environment = "dev"
  region      = "us-east-1"
  api_name    = "example-websocket-api"
  stage_name  = "dev"

  # Example with hardcoded Lambda ARNs
  # In production, use terraform_remote_state or data sources

  # Custom routes for your WebSocket API
  # These handle specific message types from the client
  routes = {
    send_message = {
      route_key  = "sendMessage"
      lambda_arn = "arn:aws:lambda:us-east-1:123456789012:function:ws-send-message"
    }
    get_data = {
      route_key  = "getData"
      lambda_arn = "arn:aws:lambda:us-east-1:123456789012:function:ws-get-data"
    }
    proxy_request = {
      route_key  = "proxyRequest"
      lambda_arn = "arn:aws:lambda:us-east-1:123456789012:function:ws-proxy-to-rest-api"
    }
  }
}

module "websocket_api" {
  source = "../"

  environment     = local.environment
  region          = local.region
  api_name        = local.api_name
  api_description = "Example WebSocket API for real-time communication with proxy to REST API"
  stage_name      = local.stage_name

  # Route selection expression - determines which route to use based on message content
  # This expects messages like: {"action": "sendMessage", "data": {...}}
  route_selection_expression = "$request.body.action"

  # Connection lifecycle handlers
  # $connect - called when client connects
  connect_lambda_arn = "arn:aws:lambda:us-east-1:123456789012:function:ws-connect-handler"

  # $disconnect - called when client disconnects
  disconnect_lambda_arn = "arn:aws:lambda:us-east-1:123456789012:function:ws-disconnect-handler"

  # $default - fallback handler for messages that don't match any route
  default_lambda_arn = "arn:aws:lambda:us-east-1:123456789012:function:ws-default-handler"

  # Custom routes
  routes = local.routes

  # Logging and monitoring
  log_retention_in_days = 7
  enable_access_logging = true
  logging_level         = "INFO"
  data_trace_enabled    = false

  # Rate limiting
  throttle_burst_limit = 5000
  throttle_rate_limit  = 10000

  # Stage variables (optional)
  stage_variables = {
    rest_api_endpoint = "https://api.example.com"
    environment       = "dev"
  }

  tags = {
    Project     = "example-project"
    ManagedBy   = "terraform"
    Environment = local.environment
    Example     = "true"
  }
}
