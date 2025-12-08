resource "aws_lambda_function" "this" {
  function_name = var.lambda_function_name
  description   = var.description
  role          = var.lambda_exec_role_arn
  handler       = var.handler
  runtime       = var.runtime
  timeout       = var.lambda_timeout
  memory_size   = var.memory_size

  # Use local file if provided, otherwise use S3
  filename      = var.filename
  s3_bucket     = var.filename == null ? var.s3_bucket : null
  s3_key        = var.filename == null ? var.s3_key : null
  source_code_hash = var.filename != null ? filebase64sha256(var.filename) : null

  architectures                  = var.architectures
  layers                        = var.layers
  publish                       = var.publish
  reserved_concurrent_executions = var.reserved_concurrent_executions

  dynamic "vpc_config" {
    for_each = var.enable_vpc ? [1] : []
    content {
      subnet_ids         = var.subnet_ids
      security_group_ids = var.security_group_ids
    }
  }

  dynamic "environment" {
    for_each = length(var.lambda_env_vars) > 0 ? [1] : []
    content {
      variables = var.lambda_env_vars
    }
  }

  dynamic "dead_letter_config" {
    for_each = var.dead_letter_target_arn != "" ? [1] : []
    content {
      target_arn = var.dead_letter_target_arn
    }
  }

  dynamic "tracing_config" {
    for_each = var.enable_xray_tracing ? [1] : []
    content {
      mode = "Active"
    }
  }

  dynamic "ephemeral_storage" {
    for_each = var.ephemeral_storage_size != null ? [1] : []
    content {
      size = var.ephemeral_storage_size
    }
  }

  kms_key_arn = var.kms_key_arn != "" ? var.kms_key_arn : null

  tags = merge(
    {
      environment = var.environment
    },
    var.tags
  )
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.lambda_function_name}"
  retention_in_days = var.log_retention_in_days

  tags = merge(
    {
      environment = var.environment
    },
    var.tags
  )
}

resource "aws_lambda_function_url" "this" {
  count              = var.enable_function_url ? 1 : 0
  function_name      = aws_lambda_function.this.function_name
  authorization_type = var.function_url_auth_type

  dynamic "cors" {
    for_each = var.function_url_cors_config != null ? [1] : []
    content {
      allow_credentials = lookup(var.function_url_cors_config, "allow_credentials", false)
      allow_origins     = lookup(var.function_url_cors_config, "allow_origins", ["*"])
      allow_methods     = lookup(var.function_url_cors_config, "allow_methods", ["*"])
      allow_headers     = lookup(var.function_url_cors_config, "allow_headers", [])
      expose_headers    = lookup(var.function_url_cors_config, "expose_headers", [])
      max_age           = lookup(var.function_url_cors_config, "max_age", 0)
    }
  }
}

resource "aws_lambda_permission" "api_gateway" {
  count         = var.enable_api_gateway_integration ? 1 : 0
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = var.api_gateway_execution_arn
}
