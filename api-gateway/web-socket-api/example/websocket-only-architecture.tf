# WebSocket-Only Architecture for Raspberry Pi Device Farm
# Cleaner architecture using reverse WebSocket connection from Pi
#
# Architecture:
#   Frontend → WebSocket API Gateway → Lambda → Pi (via reverse WebSocket)
#
# Benefits:
#   ✅ No port forwarding needed on Pi
#   ✅ No VPN or dynamic DNS required
#   ✅ Pi stays behind firewall (more secure)
#   ✅ Single protocol (WebSocket) for all communication
#   ✅ Bidirectional real-time communication
#   ✅ Works with Pi on any network (home, cellular, etc.)

provider "aws" {
  region = "us-east-1"
}

locals {
  environment = "production"
  region      = "us-east-1"
  stage_name  = "prod"

  # Single Lambda function that handles WebSocket communication
  lambda_function_arn  = "arn:aws:lambda:us-east-1:123456789012:function:pi-proxy-api"
  lambda_function_name = "pi-proxy-api"

  common_tags = {
    Project     = "pi-device-farm"
    ManagedBy   = "terraform"
    Environment = local.environment
  }
}

# ==================== WebSocket API Gateway ====================
# Single API Gateway handles:
#   1. Frontend client connections
#   2. Raspberry Pi reverse connections
#   3. Bidirectional message routing

module "websocket_api" {
  source = "../../web-socket-api"

  environment     = local.environment
  region          = local.region
  api_name        = "pi-device-farm-websocket"
  api_description = "WebSocket API for Raspberry Pi Device Farm - Unified WebSocket communication"
  stage_name      = local.stage_name

  # Route selection based on message action
  route_selection_expression = "$request.body.action"

  # Connection lifecycle handlers
  # All connections (frontend and Pi devices) go through these routes
  connect_lambda_arn    = local.lambda_function_arn
  disconnect_lambda_arn = local.lambda_function_arn
  default_lambda_arn    = local.lambda_function_arn

  # Custom routes for different message types
  routes = {
    # Frontend sends piCommand to execute operations on Pi
    pi_command = {
      route_key  = "piCommand"
      lambda_arn = local.lambda_function_arn
    }

    # Frontend sends direct commands to specific device
    send_command = {
      route_key  = "sendCommand"
      lambda_arn = local.lambda_function_arn
    }

    # Pi sends responses back
    pi_response = {
      route_key  = "piResponse"
      lambda_arn = local.lambda_function_arn
    }

    # Pi sends status updates (heartbeat, device changes, etc.)
    pi_status = {
      route_key  = "piStatus"
      lambda_arn = local.lambda_function_arn
    }

    # Frontend requests device list
    list_devices = {
      route_key  = "listDevices"
      lambda_arn = local.lambda_function_arn
    }
  }

  # Logging and monitoring
  log_retention_in_days = 30
  enable_access_logging = true
  logging_level         = "INFO"
  data_trace_enabled    = false

  # Rate limiting
  throttle_burst_limit = 5000
  throttle_rate_limit  = 10000

  # Stage variables
  stage_variables = {
    environment = local.environment
    version     = "v2"  # v2 = WebSocket-only architecture
  }

  tags = local.common_tags
}

# ==================== DynamoDB for Connection Management ====================
# Store WebSocket connections for routing messages

resource "aws_dynamodb_table" "websocket_connections" {
  name         = "pi-websocket-connections-${local.environment}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "connectionId"

  attribute {
    name = "connectionId"
    type = "S"
  }

  attribute {
    name = "connectionType"
    type = "S"
  }

  attribute {
    name = "deviceId"
    type = "S"
  }

  # GSI to lookup connections by type (frontend vs device)
  global_secondary_index {
    name            = "connectionType-index"
    hash_key        = "connectionType"
    projection_type = "ALL"
  }

  # GSI to lookup device connections by deviceId
  global_secondary_index {
    name            = "deviceId-index"
    hash_key        = "deviceId"
    projection_type = "ALL"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  tags = merge(local.common_tags, {
    Name = "WebSocket Connections"
  })
}

# Lambda needs permission to access DynamoDB
resource "aws_iam_policy" "lambda_dynamodb" {
  name        = "pi-lambda-dynamodb-${local.environment}"
  description = "Allow Lambda to access WebSocket connections table"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = [
          aws_dynamodb_table.websocket_connections.arn,
          "${aws_dynamodb_table.websocket_connections.arn}/index/*"
        ]
      }
    ]
  })
}

# Lambda needs permission to send messages back through WebSocket
resource "aws_iam_policy" "lambda_websocket_management" {
  name        = "pi-lambda-websocket-management-${local.environment}"
  description = "Allow Lambda to send messages through WebSocket API"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "execute-api:ManageConnections"
        ]
        Resource = "${module.websocket_api.websocket_api_execution_arn}/*"
      }
    ]
  })
}

# Attach policies to Lambda execution role
# Note: You'll need to attach these to your existing Lambda role
resource "aws_iam_role_policy_attachment" "lambda_dynamodb" {
  role       = local.lambda_function_name  # Your Lambda's IAM role name
  policy_arn = aws_iam_policy.lambda_dynamodb.arn
}

resource "aws_iam_role_policy_attachment" "lambda_websocket" {
  role       = local.lambda_function_name  # Your Lambda's IAM role name
  policy_arn = aws_iam_policy.lambda_websocket_management.arn
}

# ==================== Outputs ====================

output "websocket_url" {
  description = "WebSocket connection URL (for both frontend and Pi)"
  value       = module.websocket_api.websocket_connection_url
}

output "frontend_connection_example" {
  description = "How frontend clients connect"
  value = {
    url = module.websocket_api.websocket_connection_url
    example_js = <<-EOT
      const ws = new WebSocket('${module.websocket_api.websocket_connection_url}');

      ws.onopen = () => {
        console.log('Connected to Pi device farm');

        // Send command to Pi via WebSocket
        ws.send(JSON.stringify({
          action: 'piCommand',
          category: 'devices',
          operation: 'list_devices'
        }));
      };

      ws.onmessage = (event) => {
        const response = JSON.parse(event.data);
        console.log('Response from Pi:', response);
      };
    EOT
  }
}

output "pi_connection_example" {
  description = "How Raspberry Pi connects (reverse connection)"
  value = {
    url = "${module.websocket_api.websocket_connection_url}?deviceId=pi-001"
    example_python = <<-EOT
      # pi_websocket_client.py
      # Run this on your Raspberry Pi to establish reverse connection

      import asyncio
      import websockets
      import json

      DEVICE_ID = "pi-001"
      WS_URL = "${module.websocket_api.websocket_connection_url}?deviceId={DEVICE_ID}"

      async def handle_command(command):
          """Execute command on Pi and return result"""
          # Your existing Pi REST API logic goes here
          category = command.get('category')
          operation = command.get('operation')
          params = command.get('params', {})

          # Example: call your existing device functions
          if category == 'devices' and operation == 'list_devices':
              # Return your actual device list
              return {"devices": [...]}

          return {"error": "Unknown command"}

      async def pi_client():
          async with websockets.connect(WS_URL) as websocket:
              print(f"Connected as {DEVICE_ID}")

              # Send registration message
              await websocket.send(json.dumps({
                  "action": "register",
                  "deviceId": DEVICE_ID,
                  "capabilities": ["devices", "wifi", "accounts"]
              }))

              # Listen for commands from Lambda
              async for message in websocket:
                  data = json.loads(message)

                  if data.get('action') == 'executeCommand':
                      result = await handle_command(data)

                      # Send response back
                      await websocket.send(json.dumps({
                          "action": "piResponse",
                          "requestId": data.get('requestId'),
                          "result": result
                      }))

      if __name__ == "__main__":
          asyncio.run(pi_client())
    EOT
  }
}

output "architecture_benefits" {
  description = "Benefits of WebSocket-only architecture"
  value = {
    no_port_forwarding = "Pi initiates connection, no inbound ports needed"
    no_vpn_required    = "Works with Pi on any network"
    firewall_friendly  = "Only outbound WebSocket connection from Pi"
    real_time          = "Bidirectional real-time communication"
    single_protocol    = "One protocol for all communication"
    scalable           = "Connection pooling in DynamoDB"
  }
}

output "dynamodb_table" {
  description = "DynamoDB table for connection management"
  value       = aws_dynamodb_table.websocket_connections.name
}

output "migration_notes" {
  description = "How to migrate from HTTP to WebSocket"
  value = <<-EOT
    Migration Steps:

    1. Update Pi software:
       - Add WebSocket client (see pi_connection_example)
       - Connect to: ${module.websocket_api.websocket_connection_url}?deviceId=YOUR_PI_ID
       - Handle incoming commands and send responses

    2. Update Lambda:
       - Remove api_client.py (HTTP client)
       - Add WebSocket message routing logic
       - Use boto3 API Gateway Management API to send messages

    3. Update frontend:
       - Replace HTTP fetch() calls with WebSocket messages
       - See frontend_connection_example for code

    4. Benefits:
       - No more network configuration on Pi
       - Real-time bidirectional communication
       - Simpler deployment (Pi works anywhere with internet)
  EOT
}
