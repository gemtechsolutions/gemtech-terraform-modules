output "websocket_api_id" {
  description = "ID of the WebSocket API Gateway"
  value       = aws_apigatewayv2_api.websocket.id
}

output "websocket_api_arn" {
  description = "ARN of the WebSocket API Gateway"
  value       = aws_apigatewayv2_api.websocket.arn
}

output "websocket_api_execution_arn" {
  description = "Execution ARN of the WebSocket API (for Lambda permissions)"
  value       = aws_apigatewayv2_api.websocket.execution_arn
}

output "websocket_api_endpoint" {
  description = "WebSocket API endpoint URL"
  value       = aws_apigatewayv2_api.websocket.api_endpoint
}

output "websocket_url" {
  description = "Full WebSocket URL with stage"
  value       = "${replace(aws_apigatewayv2_api.websocket.api_endpoint, "wss://", "")}/${var.stage_name}"
}

output "websocket_connection_url" {
  description = "WebSocket connection URL (wss://)"
  value       = "wss://${replace(aws_apigatewayv2_api.websocket.api_endpoint, "wss://", "")}/${var.stage_name}"
}

output "websocket_stage_name" {
  description = "Name of the WebSocket API stage"
  value       = aws_apigatewayv2_stage.websocket.name
}

output "websocket_stage_arn" {
  description = "ARN of the WebSocket API stage"
  value       = aws_apigatewayv2_stage.websocket.arn
}

output "websocket_stage_invoke_url" {
  description = "Invoke URL of the WebSocket API stage"
  value       = aws_apigatewayv2_stage.websocket.invoke_url
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch Log Group for WebSocket API"
  value       = aws_cloudwatch_log_group.websocket_api.name
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch Log Group for WebSocket API"
  value       = aws_cloudwatch_log_group.websocket_api.arn
}

output "route_ids" {
  description = "Map of route keys to route IDs"
  value = merge(
    { for k, v in aws_apigatewayv2_route.routes : k => v.id },
    var.connect_lambda_arn != null ? { connect = aws_apigatewayv2_route.connect[0].id } : {},
    var.disconnect_lambda_arn != null ? { disconnect = aws_apigatewayv2_route.disconnect[0].id } : {},
    var.default_lambda_arn != null ? { default = aws_apigatewayv2_route.default[0].id } : {}
  )
}

output "integration_ids" {
  description = "Map of route keys to integration IDs"
  value = merge(
    { for k, v in aws_apigatewayv2_integration.routes : k => v.id },
    var.connect_lambda_arn != null ? { connect = aws_apigatewayv2_integration.connect[0].id } : {},
    var.disconnect_lambda_arn != null ? { disconnect = aws_apigatewayv2_integration.disconnect[0].id } : {},
    var.default_lambda_arn != null ? { default = aws_apigatewayv2_integration.default[0].id } : {}
  )
}

output "authorizer_id" {
  description = "ID of the Cognito authorizer (if enabled)"
  value       = var.enable_cognito_authorizer ? aws_apigatewayv2_authorizer.cognito[0].id : null
}

output "authorizer_enabled" {
  description = "Whether Cognito authorization is enabled"
  value       = var.enable_cognito_authorizer
}
