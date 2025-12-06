provider "aws" {
  region = "us-east-1"
}

locals {
  environment = "test"
  region      = "us-east-1"
  api_name    = "example-api"
  stage_name  = "test"

  api_resources = {
    hello = {
      path_part  = "hello"
      lambda_arn = "arn:aws:lambda:us-east-1:123456789012:function:hello-world"
      methods = {
        "GET" = {
          integration_uri     = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:123456789012:function:hello-world/invocations"
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
  source        = "../"
  environment   = local.environment
  region        = local.region
  api_name      = local.api_name
  stage_name    = local.stage_name
  api_resources = local.api_resources
}
