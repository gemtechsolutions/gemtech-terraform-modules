provider "aws" {
  region = "us-east-1"
}

locals {
  environment = "dev"
  region      = "us-east-1"
  api_name    = "example-http-api"
  stage_name  = "dev"

  api_resources = {
    users = {
      path_part  = "users"
      lambda_arn = "arn:aws:lambda:us-east-1:123456789012:function:users-api"
      methods = {
        "GET" = {
          integration_uri     = "arn:aws:lambda:us-east-1:123456789012:function:users-api"
          status_code         = "200"
          response_models     = { "application/json" = "Empty" }
          response_parameters = {}
        }
        "POST" = {
          integration_uri     = "arn:aws:lambda:us-east-1:123456789012:function:users-api"
          status_code         = "201"
          response_models     = { "application/json" = "Empty" }
          response_parameters = {}
        }
      }
      proxy = true
    }
    products = {
      path_part  = "products"
      lambda_arn = "arn:aws:lambda:us-east-1:123456789012:function:products-api"
      methods = {
        "GET" = {
          integration_uri     = "arn:aws:lambda:us-east-1:123456789012:function:products-api"
          status_code         = "200"
          response_models     = { "application/json" = "Empty" }
          response_parameters = {}
        }
      }
      proxy = true
    }
  }
}

module "http_api" {
  source = "../"

  environment     = local.environment
  region          = local.region
  api_name        = local.api_name
  api_description = "Example HTTP API Gateway for Lambda functions"
  stage_name      = local.stage_name

  api_resources = local.api_resources

  # Logging and monitoring
  log_retention_in_days = 7
  enable_metrics        = true
  logging_level         = "INFO"
  enable_data_trace     = false
  enable_access_logging = true

  # Rate limiting
  throttling_burst_limit = 5000
  throttling_rate_limit  = 10000

  # CORS
  enable_cors = true

  payload_format_version = "2.0"

  tags = {
    Project     = "example-project"
    ManagedBy   = "terraform"
    Environment = local.environment
    Example     = "true"
  }
}
