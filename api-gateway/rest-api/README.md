# API Gateway REST Module

## Example Usage

```hcl
module "api_gateway" {
  source        = "git::https://github.com/YOUR_ORG/terraform-modules.git//api-gateway/api-gateway-rest?ref=main"
  environment   = "test"
  region        = "us-east-1"
  api_name      = "example-api"
  stage_name    = "test"

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
```
