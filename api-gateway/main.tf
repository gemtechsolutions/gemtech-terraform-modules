resource "aws_api_gateway_rest_api" "this" {
  name = var.api_name
}

resource "aws_api_gateway_resource" "resource" {
  for_each = var.api_resources

  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = each.value.path_part
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
  resource_id   = aws_api_gateway_resource.resource[each.value.resource_key].id
  http_method   = upper(each.value.method_name)
  authorization = "NONE"
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
  resource_id             = aws_api_gateway_resource.resource[each.value.resource_key].id
  http_method             = upper(each.value.method_name)
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = each.value.config.integration_uri
}

resource "aws_api_gateway_resource" "proxy" {
  for_each = {
    for key, value in var.api_resources : key => value
    if value.proxy
  }

  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_resource.resource[each.key].id
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

resource "aws_lambda_permission" "apigw" {
  for_each = {
    for key, value in var.api_resources : key => value
    if value.proxy
  }

  statement_id  = "AllowAPIGatewayInvoke-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = each.value.lambda_arn
  principal     = "apigateway.amazonaws.com"

  source_arn = "arn:aws:execute-api:${var.region}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.this.id}/*/${aws_api_gateway_method.proxy[each.key].http_method}/${each.key}/*"
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
  stage_name    = var.environment
}

