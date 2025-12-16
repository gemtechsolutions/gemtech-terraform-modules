# HTTP API Module Example

This example shows how to use the HTTP API module to expose Lambda functions with optional Cognito JWT authentication.

## What it creates
- HTTP API with CORS, access logging, and throttling
- Proxy-style resources under `/users` and `/products`
- Optional Cognito JWT authorizer example in `http-api-with-cognito.tf`

## How to use
1) Update ARNs and region in `main.tf`.
2) Initialize: `terraform init`
3) Review: `terraform plan`
4) Deploy: `terraform apply`
5) Outputs: `terraform output`

## Test requests
```
# Users endpoint
curl "$(terraform output -raw http_api_invoke_url)/users"

# Products endpoint
curl "$(terraform output -raw http_api_invoke_url)/products"
```

If using Cognito, pass an `Authorization` header with a valid ID token:
```
TOKEN="your-id-token"
curl -H "Authorization: $TOKEN" "$(terraform output -raw http_api_invoke_url)/api/hello"
```
