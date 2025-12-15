# CloudWatch Log Group for WebSocket API
resource "aws_cloudwatch_log_group" "websocket_api" {
  name              = "/aws/apigateway/websocket/${var.api_name}"
  retention_in_days = var.log_retention_in_days

  tags = merge(
    {
      environment = var.environment
    },
    var.tags
  )
}

# WebSocket API
resource "aws_apigatewayv2_api" "websocket" {
  name                       = var.api_name
  protocol_type              = "WEBSOCKET"
  route_selection_expression = var.route_selection_expression
  description                = var.api_description

  tags = merge(
    {
      environment = var.environment
    },
    var.tags
  )
}

# Cognito Authorizer (optional)
resource "aws_apigatewayv2_authorizer" "cognito" {
  count = var.enable_cognito_authorizer ? 1 : 0

  api_id           = aws_apigatewayv2_api.websocket.id
  authorizer_type  = "JWT"
  identity_sources = var.identity_source
  name             = var.authorizer_name

  jwt_configuration {
    audience = var.cognito_user_pool_arns
    issuer   = "https://cognito-idp.${var.region}.amazonaws.com/${var.cognito_user_pool_arns[0]}"
  }
}

# Lambda integrations for custom routes
resource "aws_apigatewayv2_integration" "routes" {
  for_each = var.routes

  api_id                    = aws_apigatewayv2_api.websocket.id
  integration_type          = "AWS_PROXY"
  integration_method        = each.value.integration_method
  integration_uri           = each.value.lambda_arn
  content_handling_strategy = each.value.content_handling
  passthrough_behavior      = each.value.passthrough_behavior
  timeout_milliseconds      = each.value.timeout_milliseconds
}

# Custom routes
resource "aws_apigatewayv2_route" "routes" {
  for_each = var.routes

  api_id    = aws_apigatewayv2_api.websocket.id
  route_key = each.value.route_key
  target    = "integrations/${aws_apigatewayv2_integration.routes[each.key].id}"
}

# $connect route integration
resource "aws_apigatewayv2_integration" "connect" {
  count = var.connect_lambda_arn != null ? 1 : 0

  api_id             = aws_apigatewayv2_api.websocket.id
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
  integration_uri    = var.connect_lambda_arn
}

# $connect route
resource "aws_apigatewayv2_route" "connect" {
  count = var.connect_lambda_arn != null ? 1 : 0

  api_id             = aws_apigatewayv2_api.websocket.id
  route_key          = "$connect"
  target             = "integrations/${aws_apigatewayv2_integration.connect[0].id}"
  authorization_type = var.enable_cognito_authorizer ? "JWT" : "NONE"
  authorizer_id      = var.enable_cognito_authorizer ? aws_apigatewayv2_authorizer.cognito[0].id : null
}

# $disconnect route integration
resource "aws_apigatewayv2_integration" "disconnect" {
  count = var.disconnect_lambda_arn != null ? 1 : 0

  api_id             = aws_apigatewayv2_api.websocket.id
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
  integration_uri    = var.disconnect_lambda_arn
}

# $disconnect route
resource "aws_apigatewayv2_route" "disconnect" {
  count = var.disconnect_lambda_arn != null ? 1 : 0

  api_id    = aws_apigatewayv2_api.websocket.id
  route_key = "$disconnect"
  target    = "integrations/${aws_apigatewayv2_integration.disconnect[0].id}"
}

# $default route integration
resource "aws_apigatewayv2_integration" "default" {
  count = var.default_lambda_arn != null ? 1 : 0

  api_id             = aws_apigatewayv2_api.websocket.id
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
  integration_uri    = var.default_lambda_arn
}

# $default route
resource "aws_apigatewayv2_route" "default" {
  count = var.default_lambda_arn != null ? 1 : 0

  api_id    = aws_apigatewayv2_api.websocket.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.default[0].id}"
}

# Lambda permissions for custom routes
resource "aws_lambda_permission" "routes" {
  for_each = var.routes

  statement_id  = "AllowWebSocketAPIInvoke-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = each.value.lambda_arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.websocket.execution_arn}/*/${each.value.route_key}"
}

# Lambda permission for $connect
resource "aws_lambda_permission" "connect" {
  count = var.connect_lambda_arn != null ? 1 : 0

  statement_id  = "AllowWebSocketAPIInvoke-connect"
  action        = "lambda:InvokeFunction"
  function_name = var.connect_lambda_arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.websocket.execution_arn}/*/$connect"
}

# Lambda permission for $disconnect
resource "aws_lambda_permission" "disconnect" {
  count = var.disconnect_lambda_arn != null ? 1 : 0

  statement_id  = "AllowWebSocketAPIInvoke-disconnect"
  action        = "lambda:InvokeFunction"
  function_name = var.disconnect_lambda_arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.websocket.execution_arn}/*/$disconnect"
}

# Lambda permission for $default
resource "aws_lambda_permission" "default" {
  count = var.default_lambda_arn != null ? 1 : 0

  statement_id  = "AllowWebSocketAPIInvoke-default"
  action        = "lambda:InvokeFunction"
  function_name = var.default_lambda_arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.websocket.execution_arn}/*/$default"
}

# WebSocket API Stage
resource "aws_apigatewayv2_stage" "websocket" {
  api_id      = aws_apigatewayv2_api.websocket.id
  name        = var.stage_name
  auto_deploy = true

  default_route_settings {
    logging_level            = var.logging_level
    data_trace_enabled       = var.data_trace_enabled
    throttling_burst_limit   = var.throttle_burst_limit
    throttling_rate_limit    = var.throttle_rate_limit
  }

  dynamic "access_log_settings" {
    for_each = var.enable_access_logging ? [1] : []
    content {
      destination_arn = aws_cloudwatch_log_group.websocket_api.arn
      format = jsonencode({
        requestId      = "$context.requestId"
        ip             = "$context.identity.sourceIp"
        requestTime    = "$context.requestTime"
        routeKey       = "$context.routeKey"
        status         = "$context.status"
        protocol       = "$context.protocol"
        responseLength = "$context.responseLength"
        integrationError = "$context.integrationErrorMessage"
      })
    }
  }

  stage_variables = var.stage_variables

  tags = merge(
    {
      environment = var.environment
    },
    var.tags
  )
}
