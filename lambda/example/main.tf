provider "aws" {
  region = "us-east-1"
}

locals {
  environment = "test"
  deployment_bucket = "example-lambda-bucket"
  subnet_ids = []
  security_group_ids = []

  lambda_functions = {
    function1 = {
      name        = "example-mail-service"
      description = "Example Mail Lambda"
      s3_key      = "lambda/example-mail.zip"
    }
    function2 = {
      name        = "example-user-service"
      description = "Example User Lambda"
      s3_key      = "lambda/example-user.zip"
    }
  }
}

# Example IAM role to pass into Lambda module
resource "aws_iam_role" "lambda_exec_role" {
  for_each = local.lambda_functions

  name = "${each.value.name}-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

module "lambda" {
  source = "../"

  for_each = local.lambda_functions

  lambda_function_name = each.value.name
  description          = each.value.description
  lambda_exec_role_arn = aws_iam_role.lambda_exec_role[each.key].arn

  handler        = "bootstrap"
  runtime        = "provided.al2"
  lambda_timeout = 300

  s3_bucket = local.deployment_bucket
  s3_key    = each.value.s3_key

  subnet_ids         = local.subnet_ids
  security_group_ids = local.security_group_ids

  lambda_env_vars = {
    ENVIRONMENT = local.environment
  }

  depends_on = []
}
