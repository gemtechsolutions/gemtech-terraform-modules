# Lambda Function Module

This module deploys AWS Lambda functions using code stored in S3, with full support for:

- VPC configuration
- Environment variables
- IAM role injection
- Flexible runtime/handler/timeouts

## 🚀 Usage

```hcl
module "lambda" {
  source = "git::https://github.com/YOUR_ORG/terraform-modules.git//lambda/lambda-api?ref=main"

  lambda_function_name = "example-function"
  description          = "My Lambda function"
  lambda_exec_role_arn = aws_iam_role.lambda_exec_role.arn

  handler        = "bootstrap"
  runtime        = "provided.al2"
  lambda_timeout = 300

  s3_bucket = "my-lambda-bucket"
  s3_key    = "path/to/code.zip"

  subnet_ids         = []
  security_group_ids = []

  lambda_env_vars = {
    ENVIRONMENT = "test"
  }

  depends_on = []
}
```

## 🔧 Inputs

| Name                   | Type           | Description                    | Required |
| ---------------------- | -------------- | ------------------------------ | -------- |
| `lambda_function_name` | `string`       | Name of the Lambda function    | ✅       |
| `description`          | `string`       | Lambda function description    | ✅       |
| `lambda_exec_role_arn` | `string`       | IAM role ARN for Lambda        | ✅       |
| `handler`              | `string`       | Lambda handler                 | ✅       |
| `runtime`              | `string`       | Lambda runtime                 | ✅       |
| `lambda_timeout`       | `number`       | Function timeout (in seconds)  | ✅       |
| `s3_bucket`            | `string`       | S3 bucket for Lambda code      | ✅       |
| `s3_key`               | `string`       | S3 key (object path)           | ✅       |
| `subnet_ids`           | `list(string)` | Subnet IDs for VPC integration | ✅       |
| `security_group_ids`   | `list(string)` | Security group IDs             | ✅       |
| `lambda_env_vars`      | `map(string)`  | Environment variables          | ✅       |
| `depends_on`           | `list(any)`    | Resources to depend on         | Optional |

## 📤 Outputs

| Name                   | Description                 |
| ---------------------- | --------------------------- |
| `lambda_function_name` | Name of the Lambda function |
| `lambda_function_arn`  | ARN of the Lambda function  |

## 📝 License

MIT
