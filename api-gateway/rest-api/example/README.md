# API Gateway Module Example

This example demonstrates how to use the API Gateway module to create a REST API with Lambda integration.

## Overview

This example creates:
- REST API Gateway with multiple endpoints
- Lambda proxy integrations
- CORS configuration
- CloudWatch logging
- Rate limiting and throttling
- X-Ray tracing

## Prerequisites

1. **Lambda Functions**: You need existing Lambda functions deployed. Update the ARNs in [main.tf](main.tf:11-45)
2. **AWS Credentials**: Configured AWS credentials with appropriate permissions
3. **Terraform**: Version 1.0 or later

## Usage

### Option 1: Hardcoded Lambda ARNs (Simple)

Use this approach when you have existing Lambda functions and know their ARNs.

```hcl
locals {
  api_resources = {
    users = {
      path_part  = "users"
      lambda_arn = "arn:aws:lambda:us-east-1:123456789012:function:users-api"
      methods = {
        "GET" = { ... }
      }
      proxy = true
    }
  }
}
```

### Option 2: Using Terraform Remote State (Recommended)

Reference Lambda functions from another Terraform state:

```hcl
data "terraform_remote_state" "lambda" {
  backend = "local"
  config = {
    path = "../../lambda/terraform.tfstate"
  }
}

locals {
  api_resources = {
    for key, lambda in data.terraform_remote_state.lambda.outputs.lambda_functions : key => {
      path_part  = key
      lambda_arn = lambda.arn
      methods = {
        "GET" = {
          integration_uri = "arn:aws:apigateway:${local.region}:lambda:path/2015-03-31/functions/${lambda.arn}/invocations"
          status_code     = "200"
          response_models = { "application/json" = "Empty" }
          response_parameters = {}
        }
      }
      proxy = true
    }
  }
}
```

### Option 3: Using Data Sources

Look up existing Lambda functions:

```hcl
data "aws_lambda_function" "users_api" {
  function_name = "users-api"
}

locals {
  api_resources = {
    users = {
      path_part  = "users"
      lambda_arn = data.aws_lambda_function.users_api.arn
      methods = { ... }
      proxy = true
    }
  }
}
```

## Deployment

### 1. Update Configuration

Edit [main.tf](main.tf) and update:
- Replace Lambda ARNs with your actual function ARNs
- Update AWS region if needed
- Customize API name and stage name
- Adjust logging and throttling settings

### 2. Initialize Terraform

```bash
cd modules/api-gateway/example
terraform init
```

### 3. Review Plan

```bash
terraform plan
```

### 4. Deploy

```bash
terraform apply
```

### 5. Get Outputs

```bash
terraform output
```

Example output:
```
api_endpoints = {
  "products" = "https://abc123xyz.execute-api.us-east-1.amazonaws.com/dev/products"
  "users" = "https://abc123xyz.execute-api.us-east-1.amazonaws.com/dev/users"
}

api_gateway_url = "https://abc123xyz.execute-api.us-east-1.amazonaws.com/dev"
```

## Testing Your API

### Test GET Request

```bash
# Users endpoint
curl https://abc123xyz.execute-api.us-east-1.amazonaws.com/dev/users

# Products endpoint
curl https://abc123xyz.execute-api.us-east-1.amazonaws.com/dev/products
```

### Test POST Request

```bash
curl -X POST https://abc123xyz.execute-api.us-east-1.amazonaws.com/dev/users \
  -H "Content-Type: application/json" \
  -d '{"name": "John Doe", "email": "john@example.com"}'
```

### Test Proxy Routes

The `proxy = true` setting enables catch-all routes:

```bash
# These will all work with proxy enabled
curl https://abc123xyz.execute-api.us-east-1.amazonaws.com/dev/users/123
curl https://abc123xyz.execute-api.us-east-1.amazonaws.com/dev/users/123/profile
curl https://abc123xyz.execute-api.us-east-1.amazonaws.com/dev/products/search?q=laptop
```

## Configuration Options

### Logging Levels

```hcl
logging_level = "INFO"  # Options: OFF, ERROR, INFO
enable_data_trace = false  # Set to true to log full request/response data
```

### Rate Limiting

```hcl
throttling_burst_limit = 5000   # Maximum burst requests
throttling_rate_limit  = 10000  # Requests per second
```

### CORS Configuration

```hcl
enable_cors = true  # Enables OPTIONS method and CORS headers
```

### Monitoring

```hcl
enable_xray_tracing = true   # Enable AWS X-Ray distributed tracing
enable_metrics      = true   # Enable CloudWatch metrics
```

## API Resource Structure

Each API resource supports:

- **path_part**: URL path segment (e.g., "users", "products")
- **lambda_arn**: ARN of the Lambda function to invoke
- **methods**: Map of HTTP methods with their configurations
  - Integration URI
  - Status code
  - Response models
  - Response parameters
- **proxy**: Enable `{proxy+}` catch-all route (recommended for REST APIs)

## CloudWatch Logs

View API Gateway logs:

```bash
aws logs tail /aws/apigateway/example-rest-api --follow
```

Example log entry:
```json
{
  "requestId": "abc123",
  "ip": "203.0.113.1",
  "httpMethod": "GET",
  "resourcePath": "/users",
  "status": 200,
  "responseLength": 1234
}
```

## Monitoring

### CloudWatch Metrics

Available metrics:
- `4XXError` - Client-side errors
- `5XXError` - Server-side errors
- `Count` - Total API requests
- `IntegrationLatency` - Lambda execution time
- `Latency` - Total request/response time

### X-Ray Tracing

When enabled, view traces in AWS X-Ray console to see:
- API Gateway → Lambda call chain
- Lambda execution time
- External service calls
- Error traces

## Clean Up

```bash
terraform destroy
```

## Troubleshooting

### 403 Forbidden Errors

**Cause**: Lambda permission not configured
**Solution**: The module automatically creates Lambda permissions, but ensure the Lambda function ARN is correct

### 502 Bad Gateway

**Cause**: Lambda function error or timeout
**Solution**: Check Lambda CloudWatch logs for errors

### CORS Errors

**Cause**: CORS not properly configured
**Solution**: Ensure `enable_cors = true` and Lambda returns proper headers:

```python
return {
    'statusCode': 200,
    'headers': {
        'Access-Control-Allow-Origin': '*',
        'Content-Type': 'application/json'
    },
    'body': json.dumps(data)
}
```

### High Latency

**Solutions**:
- Enable Lambda provisioned concurrency
- Optimize Lambda cold starts
- Use Lambda layers for dependencies
- Enable X-Ray tracing to identify bottlenecks

## Advanced Usage

### Multiple HTTP Methods

```hcl
methods = {
  "GET" = {
    integration_uri     = "..."
    status_code         = "200"
    response_models     = { "application/json" = "Empty" }
    response_parameters = {}
  }
  "POST" = {
    integration_uri     = "..."
    status_code         = "201"
    response_models     = { "application/json" = "Empty" }
    response_parameters = {}
  }
  "PUT" = {
    integration_uri     = "..."
    status_code         = "200"
    response_models     = { "application/json" = "Empty" }
    response_parameters = {}
  }
  "DELETE" = {
    integration_uri     = "..."
    status_code         = "204"
    response_models     = { "application/json" = "Empty" }
    response_parameters = {}
  }
}
```

### Custom Domain Name

Add a custom domain (not included in this module):

```bash
# Create certificate in ACM
# Create custom domain in API Gateway
# Create Route53 record
```

### API Keys and Usage Plans

Add API key authentication (extend the module):

```hcl
resource "aws_api_gateway_api_key" "key" {
  name = "my-api-key"
}

resource "aws_api_gateway_usage_plan" "plan" {
  name = "my-usage-plan"

  api_stages {
    api_id = module.api_gateway.api_gateway_id
    stage  = module.api_gateway.api_gateway_stage_name
  }

  quota_settings {
    limit  = 10000
    period = "DAY"
  }

  throttle_settings {
    burst_limit = 200
    rate_limit  = 100
  }
}
```

## Learn More

- [API Gateway Module Documentation](../README.md)
- [AWS API Gateway Documentation](https://docs.aws.amazon.com/apigateway/)
- [Lambda Proxy Integration](https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-lambda-proxy-integrations.html)
