resource "aws_lambda_function" "this" {
  function_name = var.lambda_function_name
  description   = var.description
  role          = var.lambda_exec_role_arn
  handler       = var.handler
  runtime       = var.runtime
  timeout       = var.lambda_timeout
  s3_bucket     = var.s3_bucket
  s3_key        = var.s3_key

  dynamic "vpc_config" {
    for_each = var.enable_vpc ? [1] : []
    content {
      subnet_ids         = var.subnet_ids
      security_group_ids = var.security_group_ids
    }
  }

  environment {
    variables = var.lambda_env_vars
  }

  tags = {
    environment = var.environment
  }
}
