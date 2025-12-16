# Build lookup tables for resource paths and methods
locals {
  base_paths = {
    for key, value in var.api_resources : key => "/${trim(value.path_part, "/")}"
    if value.parent_key == null || value.parent_key == ""
  }

  nested_paths = {
    for key, value in var.api_resources : key => "${local.base_paths[value.parent_key]}/${trim(value.path_part, "/")}"
    if value.parent_key != null && value.parent_key != ""
  }

  resource_paths = merge(local.base_paths, local.nested_paths)

  method_configs = {
    for pair in flatten([
      for resource_key, resource in var.api_resources : [
        for method_name, method_config in resource.methods : {
          key = "${resource_key}-${method_name}"
          value = {
            resource_key = resource_key
            method_name  = upper(method_name)
            config       = method_config
            auth_mode    = coalesce(resource.authorization, "JWT")
            lambda_arn   = resource.lambda_arn
          }
        }
      ]
    ]) : pair.key => pair.value
  }

  proxy_resources = {
    for key, value in var.api_resources : key => value
    if value.proxy
  }

  cognito_user_pool_id = var.cognito_user_pool_id != null ? var.cognito_user_pool_id : (
    length(var.cognito_user_pool_arns) > 0 ? regexreplace(var.cognito_user_pool_arns[0], "arn:aws:cognito-idp:[^:]+:\\d+:userpool\\/", "") : null
  )

  cognito_audience = var.cognito_audience
}

# CloudWatch Log Group for HTTP API
resource "aws_cloudwatch_log_group" "http_api" {
  name              = "/aws/http-api/${var.api_name}"
  retention_in_days = var.log_retention_in_days

  tags = merge(
    {
      environment = var.environment
    },
    var.tags
  )
}

# HTTP API
resource "aws_apigatewayv2_api" "http" {
  name          = var.api_name
  protocol_type = "HTTP"
  description   = var.api_description

  dynamic "cors_configuration" {
    for_each = var.enable_cors ? [1] : []

    content {
      allow_credentials = lookup(var.cors_configuration, "allow_credentials", false)
      allow_headers     = lookup(var.cors_configuration, "allow_headers", ["*"])
      allow_methods     = lookup(var.cors_configuration, "allow_methods", ["*"])
      allow_origins     = lookup(var.cors_configuration, "allow_origins", ["*"])
      expose_headers    = lookup(var.cors_configuration, "expose_headers", [])
      max_age           = lookup(var.cors_configuration, "max_age", null)
    }
  }

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

  api_id           = aws_apigatewayv2_api.http.id
  authorizer_type  = "JWT"
  identity_sources = var.identity_source
  name             = var.authorizer_name

  jwt_configuration {
    audience = local.cognito_audience
    issuer   = local.cognito_user_pool_id != null ? "https://cognito-idp.${var.region}.amazonaws.com/${local.cognito_user_pool_id}" : null
  }
}

# Integrations for explicitly defined methods
resource "aws_apigatewayv2_integration" "method" {
  for_each = local.method_configs

  api_id                 = aws_apigatewayv2_api.http.id
  integration_type       = "AWS_PROXY"
  integration_uri        = each.value.config.integration_uri
  payload_format_version = var.payload_format_version
}

# Routes for explicitly defined methods
resource "aws_apigatewayv2_route" "method" {
  for_each = local.method_configs

  api_id    = aws_apigatewayv2_api.http.id
  route_key = "${each.value.method_name} ${local.resource_paths[each.value.resource_key]}"
  target    = "integrations/${aws_apigatewayv2_integration.method[each.key].id}"

  authorization_type = var.enable_cognito_authorizer && each.value.auth_mode == "JWT" ? "JWT" : "NONE"
  authorizer_id      = var.enable_cognito_authorizer && each.value.auth_mode == "JWT" ? aws_apigatewayv2_authorizer.cognito[0].id : null
}

# Proxy integrations (ANY /path/{proxy+})
resource "aws_apigatewayv2_integration" "proxy" {
  for_each = local.proxy_resources

  api_id                 = aws_apigatewayv2_api.http.id
  integration_type       = "AWS_PROXY"
  integration_uri        = each.value.lambda_arn
  payload_format_version = var.payload_format_version
}

resource "aws_apigatewayv2_route" "proxy" {
  for_each = local.proxy_resources

  api_id    = aws_apigatewayv2_api.http.id
  route_key = "ANY ${local.resource_paths[each.key]}/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.proxy[each.key].id}"

  authorization_type = var.enable_cognito_authorizer && coalesce(each.value.authorization, "JWT") == "JWT" ? "JWT" : "NONE"
  authorizer_id      = var.enable_cognito_authorizer && coalesce(each.value.authorization, "JWT") == "JWT" ? aws_apigatewayv2_authorizer.cognito[0].id : null
}

# Lambda permissions for method-level routes
resource "aws_lambda_permission" "method" {
  for_each = {
    for key, value in local.method_configs : key => value
    if value.lambda_arn != null
  }

  statement_id  = "AllowHTTPAPIInvoke-method-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = each.value.lambda_arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http.execution_arn}/*/*"
}

# Lambda permissions for proxy routes
resource "aws_lambda_permission" "proxy" {
  for_each = {
    for key, value in local.proxy_resources : key => value
    if value.lambda_arn != null
  }

  statement_id  = "AllowHTTPAPIInvoke-proxy-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = each.value.lambda_arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http.execution_arn}/*/*"
}

# HTTP API Stage
resource "aws_apigatewayv2_stage" "http" {
  api_id      = aws_apigatewayv2_api.http.id
  name        = var.stage_name
  auto_deploy = true

  default_route_settings {
    detailed_metrics_enabled = var.enable_metrics
    logging_level            = var.logging_level
    data_trace_enabled       = var.enable_data_trace
    throttling_burst_limit   = var.throttling_burst_limit
    throttling_rate_limit    = var.throttling_rate_limit
  }

  dynamic "access_log_settings" {
    for_each = var.enable_access_logging ? [1] : []

    content {
      destination_arn = aws_cloudwatch_log_group.http_api.arn
      format = jsonencode({
        requestId      = "$context.requestId"
        ip             = "$context.identity.sourceIp"
        requestTime    = "$context.requestTime"
        httpMethod     = "$context.httpMethod"
        routeKey       = "$context.routeKey"
        status         = "$context.status"
        protocol       = "$context.protocol"
        responseLength = "$context.responseLength"
        error          = "$context.integrationErrorMessage"
      })
    }
  }

  tags = merge(
    {
      environment = var.environment
    },
    var.tags
  )
}
