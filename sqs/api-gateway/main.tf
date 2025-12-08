# IAM role for API Gateway to write logs to CloudWatch
resource "aws_iam_role" "cloudwatch" {
  name = "api-gateway-cloudwatch-global"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "apigateway.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role       = aws_iam_role.cloudwatch.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

# Set the CloudWatch role at the account level (one-time setup per region)
resource "aws_api_gateway_account" "this" {
  cloudwatch_role_arn = aws_iam_role.cloudwatch.arn
}

resource "aws_api_gateway_rest_api" "this" {
  name        = var.api_name
  description = var.api_description

  endpoint_configuration {
    types = [var.endpoint_type]
  }

  tags = merge(
    {
      environment = var.environment
    },
    var.tags
  )

  depends_on = [aws_api_gateway_account.this]
}

# Base resources (parent_key is null or empty string)
resource "aws_api_gateway_resource" "base_resource" {
  for_each = {
    for key, value in var.api_resources : key => value
    if value.parent_key == null || value.parent_key == ""
  }

  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = each.value.path_part
}

# Nested resources (parent_key is a non-empty string)
resource "aws_api_gateway_resource" "nested_resource" {
  for_each = {
    for key, value in var.api_resources : key => value
    if value.parent_key != null && value.parent_key != ""
  }

  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_resource.base_resource[each.value.parent_key].id
  path_part   = each.value.path_part

  depends_on = [aws_api_gateway_resource.base_resource]
}

# Unified lookup for both base and nested resources
locals {
  all_resources = merge(
    { for k, v in aws_api_gateway_resource.base_resource : k => v },
    { for k, v in aws_api_gateway_resource.nested_resource : k => v }
  )
}

resource "aws_api_gateway_method" "method" {
  for_each = {
    for pair in flatten([
      for resource_key, resource in var.api_resources :
      [
        for method_name, method_config in resource.methods :
        {
          key = "${resource_key}-${method_name}"
          value = {
            resource_key = resource_key
            method_name  = method_name
            config       = method_config
          }
        }
      ]
    ]) : pair.key => pair.value
  }

  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = local.all_resources[each.value.resource_key].id
  http_method   = upper(each.value.method_name)
  authorization = "NONE"

  depends_on = [
    aws_api_gateway_resource.base_resource,
    aws_api_gateway_resource.nested_resource
  ]
}

resource "aws_api_gateway_integration" "integration" {
  for_each = {
    for pair in flatten([
      for resource_key, resource in var.api_resources :
      [
        for method_name, method_config in resource.methods :
        {
          key = "${resource_key}-${method_name}"
          value = {
            resource_key = resource_key
            method_name  = method_name
            config       = method_config
          }
        }
      ]
    ]) : pair.key => pair.value
  }

  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = local.all_resources[each.value.resource_key].id
  http_method             = upper(each.value.method_name)
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = each.value.config.integration_uri

  depends_on = [aws_api_gateway_method.method]
}

resource "aws_api_gateway_resource" "proxy" {
  for_each = {
    for key, value in var.api_resources : key => value
    if value.proxy
  }

  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = local.all_resources[each.key].id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy" {
  for_each = {
    for key, value in var.api_resources : key => value
    if value.proxy
  }

  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.proxy[each.key].id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "proxy" {
  for_each = {
    for key, value in var.api_resources : key => value
    if value.proxy
  }

  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.proxy[each.key].id
  http_method             = aws_api_gateway_method.proxy[each.key].http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${each.value.lambda_arn}/invocations"
}

resource "aws_lambda_permission" "apigw_proxy" {
  for_each = {
    for key, value in var.api_resources : key => value
    if value.proxy && value.lambda_arn != null
  }

  statement_id  = "AllowAPIGatewayInvoke-proxy-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = each.value.lambda_arn
  principal     = "apigateway.amazonaws.com"

  source_arn = "arn:aws:execute-api:${var.region}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.this.id}/*/*"
}

resource "aws_lambda_permission" "apigw_method" {
  for_each = {
    for pair in flatten([
      for resource_key, resource in var.api_resources :
      [
        for method_name, method_config in resource.methods :
        {
          key          = "${resource_key}-${method_name}"
          lambda_arn   = resource.lambda_arn
          method_name  = method_name
        }
      ] if resource.lambda_arn != null
    ]) : pair.key => pair
  }

  statement_id  = "AllowAPIGatewayInvoke-method-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = each.value.lambda_arn
  principal     = "apigateway.amazonaws.com"

  source_arn = "arn:aws:execute-api:${var.region}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.this.id}/*/*"
}

resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [
    aws_api_gateway_method.method,
    aws_api_gateway_integration.integration,
    aws_api_gateway_method.proxy,
    aws_api_gateway_integration.proxy
  ]

  rest_api_id = aws_api_gateway_rest_api.this.id

  triggers = {
    redeployment = sha1(jsonencode(var.api_resources))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "stage" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  deployment_id = aws_api_gateway_deployment.deployment.id
  stage_name    = var.stage_name

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      caller         = "$context.identity.caller"
      user           = "$context.identity.user"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      resourcePath   = "$context.resourcePath"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }

  xray_tracing_enabled = var.enable_xray_tracing

  tags = merge(
    {
      environment = var.environment
    },
    var.tags
  )
}

resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/apigateway/${var.api_name}"
  retention_in_days = var.log_retention_in_days

  tags = merge(
    {
      environment = var.environment
    },
    var.tags
  )
}

resource "aws_api_gateway_method_settings" "all" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  stage_name  = aws_api_gateway_stage.stage.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled        = var.enable_metrics
    logging_level          = var.logging_level
    data_trace_enabled     = var.enable_data_trace
    throttling_burst_limit = var.throttling_burst_limit
    throttling_rate_limit  = var.throttling_rate_limit
  }
}

# CORS configuration for OPTIONS method (only for resources with lambda_arn)
resource "aws_api_gateway_method" "options" {
  for_each = var.enable_cors ? {
    for key, value in var.api_resources : key => value
    if value.lambda_arn != null
  } : {}

  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = local.all_resources[each.key].id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options" {
  for_each = var.enable_cors ? {
    for key, value in var.api_resources : key => value
    if value.lambda_arn != null
  } : {}

  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = local.all_resources[each.key].id
  http_method = aws_api_gateway_method.options[each.key].http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "options" {
  for_each = var.enable_cors ? {
    for key, value in var.api_resources : key => value
    if value.lambda_arn != null
  } : {}

  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = local.all_resources[each.key].id
  http_method = aws_api_gateway_method.options[each.key].http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "options" {
  for_each = var.enable_cors ? {
    for key, value in var.api_resources : key => value
    if value.lambda_arn != null
  } : {}

  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = local.all_resources[each.key].id
  http_method = aws_api_gateway_method.options[each.key].http_method
  status_code = aws_api_gateway_method_response.options[each.key].status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,PUT,DELETE,PATCH,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

