output "websocket_api_id" {
  description = "ID of the WebSocket API Gateway"
  value       = module.websocket_api.websocket_api_id
}

output "websocket_api_arn" {
  description = "ARN of the WebSocket API Gateway"
  value       = module.websocket_api.websocket_api_arn
}

output "websocket_api_execution_arn" {
  description = "Execution ARN for Lambda permissions"
  value       = module.websocket_api.websocket_api_execution_arn
}

output "websocket_api_endpoint" {
  description = "WebSocket API endpoint URL"
  value       = module.websocket_api.websocket_api_endpoint
}

output "websocket_connection_url" {
  description = "Full WebSocket connection URL (use this to connect from your frontend)"
  value       = module.websocket_api.websocket_connection_url
}

output "websocket_stage_name" {
  description = "WebSocket API stage name"
  value       = module.websocket_api.websocket_stage_name
}

output "cloudwatch_log_group_name" {
  description = "CloudWatch Log Group name for WebSocket API"
  value       = module.websocket_api.cloudwatch_log_group_name
}

output "route_ids" {
  description = "Map of route keys to route IDs"
  value       = module.websocket_api.route_ids
}

output "integration_ids" {
  description = "Map of route keys to integration IDs"
  value       = module.websocket_api.integration_ids
}

output "example_connection_command" {
  description = "Example command to test WebSocket connection using wscat"
  value       = "wscat -c ${module.websocket_api.websocket_connection_url}"
}

output "example_message_format" {
  description = "Example message format to send via WebSocket"
  value = {
    send_message = jsonencode({
      action = "sendMessage"
      data = {
        message = "Hello, WebSocket!"
      }
    })
    get_data = jsonencode({
      action = "getData"
      data = {
        id = "123"
      }
    })
    proxy_request = jsonencode({
      action = "proxyRequest"
      data = {
        path   = "/api/users"
        method = "GET"
      }
    })
  }
}
