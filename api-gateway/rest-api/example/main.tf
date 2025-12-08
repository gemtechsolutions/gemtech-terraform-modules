provider "aws" {
  region = "us-east-1"
}

locals {
  environment = "dev"
  region      = "us-east-1"
  api_name    = "example-rest-api"
  stage_name  = "dev"

  # Example with hardcoded Lambda ARNs
  # In production, use terraform_remote_state or data sources
  api_resources = {
    users = {
      path_part  = "users"
      lambda_arn = "arn:aws:lambda:us-east-1:123456789012:function:users-api"
      methods = {
        "GET" = {
          integration_uri     = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:123456789012:function:users-api/invocations"
          status_code         = "200"
          response_models     = { "application/json" = "Empty" }
          response_parameters = {}
        }
        "POST" = {
          integration_uri     = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:123456789012:function:users-api/invocations"
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
          integration_uri     = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:123456789012:function:products-api/invocations"
          status_code         = "200"
          response_models     = { "application/json" = "Empty" }
          response_parameters = {}
        }
      }
      proxy = true
    }
  }
}

module "api_gateway" {
  source = "../"

  environment     = local.environment
  region          = local.region
  api_name        = local.api_name
  api_description = "Example REST API Gateway for Lambda functions"
  stage_name      = local.stage_name
  endpoint_type   = "REGIONAL"

  api_resources = local.api_resources

  # Logging and monitoring
  log_retention_in_days = 7
  enable_xray_tracing   = true
  enable_metrics        = true
  logging_level         = "INFO"
  enable_data_trace     = false

  # Rate limiting
  throttling_burst_limit = 5000
  throttling_rate_limit  = 10000

  # CORS
  enable_cors = true

  tags = {
    Project     = "example-project"
    ManagedBy   = "terraform"
    Environment = local.environment
    Example     = "true"
  }
}
